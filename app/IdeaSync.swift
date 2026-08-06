// IdeaSync —— Ideas 仓库的桌面应用
//
// 四个标签页：
//   INBOX —— 待分流的 idea + 冷藏区 SOMEDAY
//   项目 —— 每个项目的断点/下一步（回来时不迷路的那两栏）
//   同步 —— 拉取远端、调 agent 更新索引、推送，带实时日志
//   设置 —— 自动推送、轮询间隔、开机启动
//
// 所有 git 与 agent 逻辑都在 sync/agent-sync.sh 里，改脚本不需要重编译本 app。

import AppKit
import SwiftUI

// MARK: - 路径

let ideasDir: String = {
    if let env = ProcessInfo.processInfo.environment["IDEAS_DIR"], !env.isEmpty { return env }
    return (NSHomeDirectory() as NSString).appendingPathComponent("Ideas")
}()

func repoPath(_ rel: String) -> String {
    (ideasDir as NSString).appendingPathComponent(rel)
}

let syncScript = repoPath("sync/agent-sync.sh")
let confFile   = repoPath("sync/agent.conf")
let logFile    = repoPath("sync/agent-sync.log")
let inboxFile  = repoPath("INBOX.md")
let projFile   = repoPath("PROJECTS.md")
let plistPath  = (NSHomeDirectory() as NSString)
    .appendingPathComponent("Library/LaunchAgents/com.thb.ideasync.plist")

// MARK: - shell

@discardableResult
func shell(_ cmd: String, cwd: String? = nil) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/bash")
    p.arguments = ["-lc", cmd]
    p.currentDirectoryURL = URL(fileURLWithPath: cwd ?? ideasDir)
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    do { try p.run() } catch { return "" }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

func notify(_ title: String, _ body: String) {
    let esc = { (s: String) in s.replacingOccurrences(of: "\"", with: "\\\"") }
    shell("osascript -e \"display notification \\\"\(esc(body))\\\" with title \\\"\(esc(title))\\\"\"")
}

// MARK: - 数据模型

struct InboxItem: Identifiable {
    let id = UUID()
    var date = ""
    var text = ""
    var raw = ""            // 原始整行，删除时按它精确匹配
}

struct Project: Identifiable {
    let id = UUID()
    var name = ""
    var badge = ""          // 🔥 / 🌊 / 🧊
    var oneLiner = ""
    var breakpoint = ""
    var nextStep = ""
    var blocker = ""
    var updated = ""
    var indexPath = ""
}

/// 解析 PROJECTS.md —— 只认 `## <标记> <名字>` 与 `- **字段**：值`（值可跨行缩进续写）
func parseProjects(_ text: String) -> [Project] {
    var out: [Project] = []
    var cur: Project? = nil
    var field = ""

    func flush() {
        if let c = cur, !c.name.isEmpty, !c.name.contains("<项目名>") { out.append(c) }
        cur = nil; field = ""
    }

    for raw in text.components(separatedBy: .newlines) {
        if raw.hasPrefix("## ") {
            flush()
            var title = String(raw.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            var badge = ""
            for mark in ["🔥", "🌊", "🧊"] where title.hasPrefix(mark) {
                badge = mark
                title = String(title.dropFirst(mark.count)).trimmingCharacters(in: .whitespaces)
            }
            cur = Project(name: title, badge: badge.isEmpty ? "•" : badge)
            continue
        }
        guard cur != nil else { continue }

        if raw.hasPrefix("- **") {
            let body = String(raw.dropFirst(4))
            guard let close = body.range(of: "**") else { field = ""; continue }
            let key = String(body[body.startIndex..<close.lowerBound])
            var val = String(body[close.upperBound...])
            for sep in ["：", ":"] where val.hasPrefix(sep) { val = String(val.dropFirst(sep.count)) }
            val = val.trimmingCharacters(in: .whitespaces)
            field = key
            switch key {
            case "一句话":   cur?.oneLiner = val
            case "断点":     cur?.breakpoint = val
            case "下一步":   cur?.nextStep = val
            case "卡点":     cur?.blocker = val
            case "更新":     cur?.updated = val
            case "文档索引":
                if let l = val.range(of: "]("), let r = val.range(of: ")", range: l.upperBound..<val.endIndex) {
                    cur?.indexPath = String(val[l.upperBound..<r.lowerBound])
                }
            default: break
            }
        } else if raw.hasPrefix("  "), !field.isEmpty {
            let cont = " " + raw.trimmingCharacters(in: .whitespaces)
            switch field {
            case "一句话":  cur?.oneLiner += cont
            case "断点":    cur?.breakpoint += cont
            case "下一步":  cur?.nextStep += cont
            case "卡点":    cur?.blocker += cont
            default: break
            }
        } else if raw.trimmingCharacters(in: .whitespaces).isEmpty == false {
            field = ""
        }
    }
    flush()
    return out
}

// MARK: - Store

final class Store: ObservableObject {
    @Published var projects: [Project] = []
    @Published var status = "尚未同步"
    @Published var detail = ""
    @Published var busy = false
    @Published var ahead = 0
    @Published var behind = 0
    @Published var liveLog = ""
    @Published var autoPush = false
    @Published var pollMinutes = 10
    @Published var launchAtLogin = false
    @Published var inboxItems: [InboxItem] = []
    @Published var somedayItems: [InboxItem] = []
    @Published var toast = ""

    var inboxCount: Int { inboxItems.count }

    private var timer: Timer?
    private var watchTimer: Timer?
    private var proc: Process?
    private var externalRunning = false

    init() {
        reload()
        autoPush = readConf("AUTO_PUSH") == "1"
        launchAtLogin = FileManager.default.fileExists(atPath: plistPath)
        startTimer()
        startWatch()
        sync()
    }

    /// 监视外部（比如上一个 app 实例遗留的孤儿脚本）正在跑的同步。
    /// 没有这个的话界面会一直停在旧状态，看起来像卡死。
    func startWatch() {
        watchTimer?.invalidate()
        watchTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self = self, !self.busy else { return }
            let pid = shell("cat '\(ideasDir)/sync/.lock/pid' 2>/dev/null")
            let alive = !pid.isEmpty && shell("kill -0 \(pid) 2>/dev/null && echo alive") == "alive"
            if alive {
                if !self.externalRunning { self.externalRunning = true }
                self.status = "后台同步进行中…"
                self.loadLogTail()
            } else if self.externalRunning {
                self.externalRunning = false
                self.reload()
                self.status = "后台同步已完成"
            }
        }
    }

    // MARK: 读取

    func reload() {
        if let t = try? String(contentsOfFile: projFile, encoding: .utf8) {
            projects = parseProjects(t)
        }
        loadInbox()
        loadSomeday()
        refreshCounts()
        loadLogTail()
    }

    func loadInbox() {
        guard let t = try? String(contentsOfFile: inboxFile, encoding: .utf8) else {
            inboxItems = []; return
        }
        inboxItems = t.components(separatedBy: .newlines)
            .filter { $0.hasPrefix("- [ ] ") }
            .map { line -> InboxItem in
                var body = String(line.dropFirst(6))
                var date = ""
                // 行首若是 YYYY-MM-DD 就单独拆出来显示
                if body.count > 10 {
                    let head = String(body.prefix(10))
                    if head.count == 10, head.filter({ $0 == "-" }).count == 2,
                       head.allSatisfy({ $0.isNumber || $0 == "-" }) {
                        date = head
                        body = String(body.dropFirst(10)).trimmingCharacters(in: .whitespaces)
                    }
                }
                return InboxItem(date: date, text: body, raw: line)
            }
    }

    /// 追加到 SOMEDAY.md 的「待归类」分区。
    /// 早期版本是无脑追加到文件末尾，结果条目落进了最后一个分区（比如「学习/研究」）
    /// 下面 —— 分类是错的。这里改成显式建一个待归类分区，宁可让你手动归类，
    /// 也不要悄悄放错地方。
    func appendToSomeday(_ dest: String, _ item: InboxItem) {
        let marker = "## 待归类（从 INBOX 移入）"
        let entry = "- \(item.date) \(item.text)"
        guard var text = try? String(contentsOfFile: dest, encoding: .utf8) else { return }

        if let r = text.range(of: marker) {
            // 插到该分区标题后面第一行
            let after = text.index(r.upperBound, offsetBy: 0)
            let head = String(text[text.startIndex..<after])
            let tail = String(text[after...])
            text = head + "\n\n" + entry + tail.replacingOccurrences(
                of: "^\n+", with: "\n", options: .regularExpression)
        } else {
            if !text.hasSuffix("\n") { text += "\n" }
            text += "\n---\n\n\(marker)\n\n> 这些是从 INBOX 移过来但还没归类的。挑个时间把它们放进上面对应的分区。\n\n\(entry)\n"
        }
        try? text.write(toFile: dest, atomically: true, encoding: .utf8)
    }

    func loadSomeday() {
        guard let t = try? String(contentsOfFile: repoPath("SOMEDAY.md"), encoding: .utf8) else {
            somedayItems = []; return
        }
        var section = ""
        var out: [InboxItem] = []
        for line in t.components(separatedBy: .newlines) {
            if line.hasPrefix("## ") {
                section = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                continue
            }
            guard line.hasPrefix("- ") else { continue }
            let body = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            if body.isEmpty { continue }          // 跳过 "-" 占位行
            out.append(InboxItem(date: section, text: body, raw: line))
        }
        somedayItems = out
    }

    /// 从 INBOX.md 删掉一行；moveTo 非空时先把它追加到那个文件
    func removeFromInbox(_ item: InboxItem, moveTo: String? = nil) {
        guard let t = try? String(contentsOfFile: inboxFile, encoding: .utf8) else { return }
        var kept: [String] = []
        var removed = false
        for line in t.components(separatedBy: .newlines) {
            if !removed && line == item.raw { removed = true; continue }
            kept.append(line)
        }
        guard removed else { flash("没找到这一条，可能已被手工改过"); return }

        if let dest = moveTo { appendToSomeday(dest, item) }
        try? kept.joined(separator: "\n").write(toFile: inboxFile, atomically: true, encoding: .utf8)
        loadInbox()
        loadSomeday()
        flash(moveTo == nil ? "已删除" : "已移入 SOMEDAY 的待归类分区")
    }

    func refreshCounts() {
        let a = shell("git rev-list --count @{u}..HEAD 2>/dev/null")
        let b = shell("git rev-list --count HEAD..@{u} 2>/dev/null")
        ahead = Int(a) ?? 0
        behind = Int(b) ?? 0
    }

    func loadLogTail() {
        liveLog = shell("tail -n 60 '\(logFile)' 2>/dev/null")
    }

    // MARK: 记 idea

    /// 追加一条到 INBOX.md。写失败必须明确报错 —— 之前这里静默失败还报「成功」，是个坑。
    func captureIdea(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let line = "- [ ] \(df.string(from: Date())) \(t)\n"

        guard let fh = FileHandle(forWritingAtPath: inboxFile) else {
            flash("写入失败：打不开 \(inboxFile)")
            return
        }
        fh.seekToEndOfFile()
        guard let data = line.data(using: .utf8) else { fh.closeFile(); flash("写入失败：编码错误"); return }
        fh.write(data)
        fh.closeFile()

        let before = inboxItems.count
        loadInbox()
        if inboxItems.count > before {
            flash("已记入 INBOX（第 \(inboxItems.count) 条）")
        } else {
            flash("写入了但没读回来，检查 INBOX.md 格式")
        }
    }

    func flash(_ msg: String) {
        toast = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if self.toast == msg { self.toast = "" }
        }
    }

    // MARK: 同步

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Double(pollMinutes) * 60,
                                     repeats: true) { [weak self] _ in self?.sync() }
    }

    func sync(force: Bool = false) {
        guard !busy else { return }
        busy = true
        status = "同步中…"
        detail = ""

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/bash")
        p.arguments = force ? [syncScript, "--force"] : [syncScript]
        p.currentDirectoryURL = URL(fileURLWithPath: ideasDir)
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        proc = p

        var buf = ""
        var result = ""
        pipe.fileHandleForReading.readabilityHandler = { [weak self] fh in
            guard let s = String(data: fh.availableData, encoding: .utf8), !s.isEmpty else { return }
            buf += s
            let lines = buf.components(separatedBy: "\n")
            for line in lines {
                if line.hasPrefix("STATUS: ") {
                    let v = String(line.dropFirst(8))
                    DispatchQueue.main.async {
                        self?.status = v
                        self?.liveLog += "\n" + v
                    }
                } else if line.hasPrefix("RESULT: ") {
                    result = String(line.dropFirst(8))
                }
            }
            buf = lines.last ?? ""
        }

        // 15 分钟保险丝，防止 agent 卡死
        let fuse = DispatchWorkItem { if p.isRunning { p.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + 900, execute: fuse)

        p.terminationHandler = { [weak self] _ in
            fuse.cancel()
            pipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async { self?.finish(result) }
        }
        do { try p.run() } catch {
            busy = false
            status = "无法启动同步脚本"
        }
    }

    private func finish(_ result: String) {
        busy = false
        proc = nil
        let parts = result.components(separatedBy: "|")
        let code = parts.first ?? "error"
        status = parts.count > 1 ? parts[1] : "未知结果"
        let df = DateFormatter(); df.dateFormat = "HH:mm"
        detail = "上次同步 " + df.string(from: Date())
        reload()
        if code == "pushed" || code == "updated" || code == "awaiting" || code == "error" {
            notify("IdeaSync", status)
        }
    }

    func push() {
        guard !busy else { return }
        busy = true
        status = "推送中…"
        DispatchQueue.global().async {
            let out = shell("git push 2>&1")
            DispatchQueue.main.async {
                self.busy = false
                let ok = !out.lowercased().contains("error")
                    && !out.lowercased().contains("rejected")
                    && !out.lowercased().contains("denied")
                self.status = ok ? "已推送" : "推送失败"
                self.detail = ok ? "" : String(out.prefix(120))
                self.liveLog += "\n$ git push\n" + out
                self.refreshCounts()
                notify("IdeaSync", self.status)
            }
        }
    }

    // MARK: 配置

    func readConf(_ key: String) -> String {
        guard let t = try? String(contentsOfFile: confFile, encoding: .utf8) else { return "" }
        for line in t.components(separatedBy: .newlines) {
            let s = line.trimmingCharacters(in: .whitespaces)
            if s.hasPrefix("\(key)=") {
                return String(s.dropFirst(key.count + 1))
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
            }
        }
        return ""
    }

    func writeConf(_ key: String, _ value: String) {
        guard let t = try? String(contentsOfFile: confFile, encoding: .utf8) else { return }
        var lines = t.components(separatedBy: .newlines)
        var found = false
        for i in lines.indices where lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("\(key)=") {
            lines[i] = "\(key)=\(value)"; found = true
        }
        if !found { lines.append("\(key)=\(value)") }
        try? lines.joined(separator: "\n").write(toFile: confFile, atomically: true, encoding: .utf8)
    }

    func setLaunchAtLogin(_ on: Bool) {
        let fm = FileManager.default
        if on {
            // 必须用 /usr/bin/open 启动 .app，而不是直接执行 bundle 里的二进制 ——
            // 后者在登录时起不来（会立刻以 0 退出，看起来像"设了自启但没生效"）。
            let bundlePath = Bundle.main.bundlePath
            let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
            "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0"><dict>
              <key>Label</key><string>com.thb.ideasync</string>
              <key>ProgramArguments</key>
              <array>
                <string>/usr/bin/open</string>
                <string>-a</string>
                <string>\(bundlePath)</string>
              </array>
              <key>RunAtLoad</key><true/>
            </dict></plist>
            """
            try? fm.createDirectory(atPath: (plistPath as NSString).deletingLastPathComponent,
                                    withIntermediateDirectories: true)
            try? plist.write(toFile: plistPath, atomically: true, encoding: .utf8)
            shell("launchctl load '\(plistPath)' 2>/dev/null")
        } else {
            shell("launchctl unload '\(plistPath)' 2>/dev/null")
            try? fm.removeItem(atPath: plistPath)
        }
        launchAtLogin = fm.fileExists(atPath: plistPath)
    }
}

// MARK: - 视图

struct RootView: View {
    @EnvironmentObject var s: Store
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            Divider()
            TabView(selection: $tab) {
                InboxTab()
                    .tabItem { Label(s.inboxCount > 0 ? "INBOX (\(s.inboxCount))" : "INBOX",
                                     systemImage: "tray") }.tag(0)
                ProjectsTab().tabItem { Label("项目", systemImage: "square.stack") }.tag(1)
                SyncTab().tabItem { Label("同步", systemImage: "arrow.triangle.2.circlepath") }.tag(2)
                SettingsTab().tabItem { Label("设置", systemImage: "gearshape") }.tag(3)
            }
            .padding(.top, 6)
        }
        .frame(minWidth: 820, minHeight: 620)
        .overlay(alignment: .bottom) {
            if !s.toast.isEmpty {
                Text(s.toast)
                    .font(.callout).padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.thickMaterial, in: Capsule())
                    .padding(.bottom, 16).transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: s.toast)
    }
}

/// 顶部：随手记 idea + 同步状态
struct TopBar: View {
    @EnvironmentObject var s: Store
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
            TextField("随手记一个 idea，回车存入 INBOX（不打断你手上的事）", text: $draft)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .onSubmit { s.captureIdea(draft); draft = "" }
            Button("记下") { s.captureIdea(draft); draft = "" }
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)

            // 常驻计数：记完立刻看到数字 +1，比一闪而过的提示可靠
            Label("\(s.inboxCount)", systemImage: "tray.fill")
                .font(.callout)
                .foregroundStyle(s.inboxCount > 0 ? .orange : .secondary)
                .help("INBOX 待分流条数")

            Divider().frame(height: 22)

            HStack(spacing: 6) {
                Circle().frame(width: 8, height: 8)
                    .foregroundStyle(s.busy ? .orange : (s.ahead > 0 || s.behind > 0 ? .blue : .green))
                Text(s.busy ? "同步中…" : s.status).font(.callout).lineLimit(1)
            }
            .frame(minWidth: 180, alignment: .leading)

            Button { s.sync() } label: { Image(systemName: "arrow.clockwise") }
                .disabled(s.busy).help("立即同步")
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

struct InboxTab: View {
    @EnvironmentObject var s: Store
    @State private var showSomeday = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("待分流").font(.title3).bold()
                Text("\(s.inboxCount) 条").foregroundStyle(.secondary)
                Spacer()
                Button("刷新") { s.loadInbox() }.controlSize(.small)
                Button("用编辑器打开") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: inboxFile))
                }.controlSize(.small)
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 10)

            if s.inboxItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle").font(.largeTitle).foregroundStyle(.green)
                    Text("INBOX 是空的").font(.headline)
                    Text("在上面的输入框记想法，会出现在这里。").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(s.inboxItems) { item in
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    if !item.date.isEmpty {
                                        Text(item.date).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Text(item.text).font(.callout).textSelection(.enabled)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 8)
                                VStack(spacing: 6) {
                                    Button("移入 SOMEDAY") {
                                        s.removeFromInbox(item, moveTo: repoPath("SOMEDAY.md"))
                                    }.controlSize(.small)
                                    Button("删除") { s.removeFromInbox(item) }
                                        .controlSize(.small)
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.quaternary.opacity(0.25),
                                        in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 20)
                }

                Text("分流规则：现在就做 → 写进 PROJECTS.md；以后可能做 → 移入 SOMEDAY；两分钟能做完 → 直接做掉；其余删掉。别让它过夜到第二周。")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 20).padding(.bottom, 14)
            }

            Divider()

            // 冷藏区 —— 移走的东西必须还能看见，否则等于丢了
            DisclosureGroup(isExpanded: $showSomeday) {
                if s.somedayItems.isEmpty {
                    Text("SOMEDAY 还是空的。").font(.caption)
                        .foregroundStyle(.secondary).padding(.vertical, 6)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(s.somedayItems) { it in
                            HStack(alignment: .top, spacing: 8) {
                                Text(it.date).font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(.quaternary, in: Capsule())
                                Text(it.text).font(.caption).textSelection(.enabled)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            } label: {
                HStack {
                    Text("冷藏区 SOMEDAY").font(.callout).bold()
                    Text("\(s.somedayItems.count) 条").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("打开文件") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: repoPath("SOMEDAY.md")))
                    }.controlSize(.small)
                }
            }
            .frame(maxHeight: 220)
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
    }
}

struct ProjectsTab: View {
    @EnvironmentObject var s: Store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("进行中的项目").font(.title3).bold()
                    Text("\(s.projects.count) 个").foregroundStyle(.secondary)
                    if s.projects.count > 3 {
                        Label("超过 3 个了，考虑挪一个进 SOMEDAY", systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.orange)
                    }
                    Spacer()
                    Label("INBOX 待分流 \(s.inboxCount)", systemImage: "tray")
                        .font(.caption).foregroundStyle(s.inboxCount > 0 ? .orange : .secondary)
                    Button("打开仓库") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: ideasDir))
                    }.controlSize(.small)
                }

                if s.projects.isEmpty {
                    Text("没解析到项目。检查 PROJECTS.md 里是否有 `## 🔥 项目名` 这样的标题。")
                        .foregroundStyle(.secondary).padding(.vertical, 30)
                }

                ForEach(s.projects) { p in ProjectCard(p: p) }
            }
            .padding(20)
        }
    }
}

struct ProjectCard: View {
    let p: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(p.badge)
                Text(p.name).font(.headline)
                Spacer()
                if !p.updated.isEmpty {
                    Text(p.updated).font(.caption).foregroundStyle(.secondary)
                }
                if !p.indexPath.isEmpty {
                    Button("文档索引") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: repoPath(p.indexPath)))
                    }.controlSize(.small)
                }
            }
            if !p.oneLiner.isEmpty {
                Text(p.oneLiner).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !p.breakpoint.isEmpty { Field("断点", p.breakpoint, "bookmark", .blue) }
            if !p.nextStep.isEmpty   { Field("下一步", p.nextStep, "arrow.right.circle", .green) }
            if !p.blocker.isEmpty    { Field("卡点", p.blocker, "exclamationmark.octagon", .orange) }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func Field(_ label: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).bold().foregroundStyle(color)
                Text(value).font(.callout).textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct SyncTab: View {
    @EnvironmentObject var s: Store

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 20) {
                Stat("待推送", s.ahead, s.ahead > 0 ? .orange : .secondary)
                Stat("待拉取", s.behind, s.behind > 0 ? .blue : .secondary)
                Spacer()
            }

            HStack(spacing: 10) {
                Button { s.sync() } label: { Label("立即同步", systemImage: "arrow.clockwise") }
                    .disabled(s.busy)
                Button { s.sync(force: true) } label: {
                    Label("强制复查", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(s.busy).help("即使没有新提交，也让 agent 重读全部文档")
                Button { s.push() } label: {
                    Label("推送 \(s.ahead) 个提交", systemImage: "arrow.up.circle")
                }
                .disabled(s.busy || s.ahead == 0)
                Spacer()
                Button("在 GitHub 打开") {
                    var u = shell("git remote get-url origin")
                    u = u.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
                         .replacingOccurrences(of: ".git", with: "")
                    if let url = URL(string: u) { NSWorkspace.shared.open(url) }
                }.controlSize(.small)
            }

            if !s.detail.isEmpty {
                Text(s.detail).font(.caption).foregroundStyle(.secondary)
            }

            Text("日志").font(.headline)
            ScrollView {
                Text(s.liveLog.isEmpty ? "（暂无）" : s.liveLog)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))

            HStack {
                Button("刷新日志") { s.loadLogTail() }.controlSize(.small)
                Button("打开完整日志") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: logFile))
                }.controlSize(.small)
            }
        }
        .padding(20)
    }

    @ViewBuilder
    private func Stat(_ label: String, _ n: Int, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(n)").font(.system(size: 28, weight: .semibold)).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct SettingsTab: View {
    @EnvironmentObject var s: Store

    var body: some View {
        Form {
            Section {
                Toggle("agent 改完索引后自动推送到 GitHub", isOn: Binding(
                    get: { s.autoPush },
                    set: { s.autoPush = $0; s.writeConf("AUTO_PUSH", $0 ? "1" : "0") }))
                Text("关闭时 agent 只在本地提交，等你在「同步」页点推送。")
                    .font(.caption).foregroundStyle(.secondary)

                Picker("轮询间隔", selection: Binding(
                    get: { s.pollMinutes },
                    set: { s.pollMinutes = $0; s.startTimer() })) {
                    ForEach([5, 10, 30, 60], id: \.self) { Text("\($0) 分钟").tag($0) }
                }
                .pickerStyle(.segmented).frame(maxWidth: 320)

                Toggle("开机自动启动", isOn: Binding(
                    get: { s.launchAtLogin },
                    set: { s.setLaunchAtLogin($0) }))
            } header: { Text("同步").font(.headline) }

            Section {
                LabeledContent("仓库") { Text(ideasDir).textSelection(.enabled) }
                LabeledContent("远端") { Text(shell("git remote get-url origin")).textSelection(.enabled) }
                LabeledContent("分支") { Text(shell("git rev-parse --abbrev-ref HEAD")) }
                HStack {
                    Button("打开仓库文件夹") { NSWorkspace.shared.open(URL(fileURLWithPath: ideasDir)) }
                    Button("编辑 PROJECTS.md") { NSWorkspace.shared.open(URL(fileURLWithPath: projFile)) }
                    Button("编辑 INBOX.md") { NSWorkspace.shared.open(URL(fileURLWithPath: inboxFile)) }
                }
            } header: { Text("仓库").font(.headline) }
        }
        .formStyle(.grouped)
        .padding(4)
    }
}

// MARK: - 启动

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let store = Store()

    func applicationDidFinishLaunching(_ n: Notification) {
        // 单实例：重复启动时把已有窗口带到前面，而不是静默多开
        if let bid = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: bid).count > 1 {
            NSApp.terminate(nil); return
        }

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "IdeaSync"
        window.center()
        window.setFrameAutosaveName("IdeaSyncMain")
        window.contentViewController =
            NSHostingController(rootView: RootView().environmentObject(store))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // 点 Dock 图标时重新打开窗口
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { window?.makeKeyAndOrderFront(nil) }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { false }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)      // 正常应用：有 Dock 图标、有窗口
app.run()
