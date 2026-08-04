// IdeaSync —— Ideas 仓库的菜单栏同步 app
//
// 职责很窄：定时调用 sync/agent-sync.sh，把状态显示在菜单栏，处理推送确认。
// 所有实际逻辑（git、agent 调用）都在那个 shell 脚本里，改脚本不需要重编译本 app。

import AppKit

// MARK: - 路径

let ideasDir: String = {
    if let env = ProcessInfo.processInfo.environment["IDEAS_DIR"], !env.isEmpty { return env }
    return (NSHomeDirectory() as NSString).appendingPathComponent("Ideas")
}()

let syncScript = (ideasDir as NSString).appendingPathComponent("sync/agent-sync.sh")
let confFile   = (ideasDir as NSString).appendingPathComponent("sync/agent.conf")
let logFile    = (ideasDir as NSString).appendingPathComponent("sync/agent-sync.log")
let plistPath  = (NSHomeDirectory() as NSString)
    .appendingPathComponent("Library/LaunchAgents/com.thb.ideasync.plist")

// MARK: - 小工具

@discardableResult
func shell(_ cmd: String, cwd: String? = nil) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/bash")
    p.arguments = ["-lc", cmd]
    if let cwd = cwd { p.currentDirectoryURL = URL(fileURLWithPath: cwd) }
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    do { try p.run() } catch { return "" }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

func notify(_ title: String, _ body: String) {
    let esc = { (s: String) in s.replacingOccurrences(of: "\"", with: "\\\"") }
    shell("osascript -e \"display notification \\\"\(esc(body))\\\" with title \\\"\(esc(title))\\\"\"")
}

// MARK: - App

final class IdeaSync: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var running: Process?

    private var busy = false
    private var statusLine = "尚未同步"
    private var detailLine = ""
    private var aheadCount = 0
    private var pollMinutes = 10

    // MARK: 生命周期

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 单实例：LSUIElement app 没有 Dock 图标，重复双击会静默多开，
        // 用户只会觉得「点了没反应」。这里直接挡掉并给出提示。
        if let bid = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: bid).count > 1 {
            notify("IdeaSync 已在运行", "看菜单栏右上角的灯泡图标 💡")
            NSApp.terminate(nil)
            return
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.behavior = .removalAllowed     // 允许用户按住 ⌘ 拖动调整位置
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        guard FileManager.default.fileExists(atPath: syncScript) else {
            statusLine = "找不到同步脚本"
            detailLine = syncScript
            setIcon("exclamationmark.triangle", label: "脚本缺失")
            return
        }

        setIcon("lightbulb")
        notify("IdeaSync 已启动", "菜单栏右上角，每 \(pollMinutes) 分钟自动检查一次")
        refreshAhead()
        startTimer()
        runSync()                       // 启动时先查一次
    }

    func applicationWillTerminate(_ notification: Notification) {
        running?.terminate()
    }

    // MARK: 菜单栏图标

    // 图标旁边始终带一小段文字。纯图标在菜单栏项多的机器上（尤其有刘海的）
    // 很容易被挤掉或看漏，带文字才找得到。
    private func setIcon(_ symbol: String, label: String = "Ideas") {
        DispatchQueue.main.async {
            guard let button = self.statusItem.button else { return }
            let img = NSImage(systemSymbolName: symbol, accessibilityDescription: "IdeaSync")
            img?.isTemplate = true
            button.image = img
            button.imagePosition = .imageLeading
            button.title = " " + label
            if img == nil { button.title = " 💡 " + label }   // 符号不可用时的兜底
        }
    }

    // MARK: 菜单

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let head = NSMenuItem(title: busy ? "同步中…" : statusLine, action: nil, keyEquivalent: "")
        head.isEnabled = false
        menu.addItem(head)

        if !detailLine.isEmpty {
            let d = NSMenuItem(title: "  " + detailLine, action: nil, keyEquivalent: "")
            d.isEnabled = false
            menu.addItem(d)
        }

        menu.addItem(.separator())

        add(menu, "立即同步", #selector(menuSyncNow), key: "r", enabled: !busy)
        add(menu, "强制复查（让 agent 重读全部文档）", #selector(menuForce), enabled: !busy)

        if aheadCount > 0 {
            menu.addItem(.separator())
            add(menu, "推送 \(aheadCount) 个待确认的提交", #selector(menuPush), enabled: !busy)
        }

        menu.addItem(.separator())

        let auto = readConf("AUTO_PUSH") == "1"
        let a = NSMenuItem(title: "agent 改完自动推送", action: #selector(menuToggleAuto), keyEquivalent: "")
        a.target = self
        a.state = auto ? .on : .off
        menu.addItem(a)

        let intervalItem = NSMenuItem(title: "轮询间隔", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for m in [5, 10, 30, 60] {
            let it = NSMenuItem(title: "\(m) 分钟", action: #selector(menuInterval(_:)), keyEquivalent: "")
            it.target = self
            it.tag = m
            it.state = (m == pollMinutes) ? .on : .off
            sub.addItem(it)
        }
        intervalItem.submenu = sub
        menu.addItem(intervalItem)

        let login = NSMenuItem(title: "开机自动启动", action: #selector(menuToggleLogin), keyEquivalent: "")
        login.target = self
        login.state = FileManager.default.fileExists(atPath: plistPath) ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        add(menu, "打开仓库文件夹", #selector(menuOpenRepo))
        add(menu, "打开 GitHub", #selector(menuOpenGitHub))
        add(menu, "查看日志", #selector(menuOpenLog))
        menu.addItem(.separator())
        add(menu, "退出 IdeaSync", #selector(menuQuit), key: "q")
    }

    private func add(_ menu: NSMenu, _ title: String, _ sel: Selector,
                     key: String = "", enabled: Bool = true) {
        let it = NSMenuItem(title: title, action: sel, keyEquivalent: key)
        it.target = self
        it.isEnabled = enabled
        menu.addItem(it)
    }

    // MARK: 菜单动作

    @objc private func menuSyncNow() { runSync() }
    @objc private func menuForce()   { runSync(force: true) }
    @objc private func menuQuit()    { NSApp.terminate(nil) }

    @objc private func menuPush() {
        busy = true
        setIcon("arrow.triangle.2.circlepath")
        DispatchQueue.global().async {
            let out = shell("git push 2>&1", cwd: ideasDir)
            DispatchQueue.main.async {
                self.busy = false
                let ok = !out.lowercased().contains("error") && !out.lowercased().contains("rejected")
                self.statusLine = ok ? "已推送" : "推送失败"
                self.detailLine = ok ? "" : String(out.prefix(80))
                self.setIcon(ok ? "checkmark.circle" : "exclamationmark.triangle",
                             label: ok ? "Ideas" : "推送失败")
                self.refreshAhead()
                notify("IdeaSync", self.statusLine)
            }
        }
    }

    @objc private func menuToggleAuto() {
        writeConf("AUTO_PUSH", readConf("AUTO_PUSH") == "1" ? "0" : "1")
    }

    @objc private func menuInterval(_ sender: NSMenuItem) {
        pollMinutes = sender.tag
        startTimer()
    }

    @objc private func menuToggleLogin() {
        let fm = FileManager.default
        if fm.fileExists(atPath: plistPath) {
            try? fm.removeItem(atPath: plistPath)
            shell("launchctl unload \(plistPath) 2>/dev/null")
        } else {
            let exe = Bundle.main.executablePath ?? ""
            let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
            "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0"><dict>
              <key>Label</key><string>com.thb.ideasync</string>
              <key>ProgramArguments</key><array><string>\(exe)</string></array>
              <key>RunAtLoad</key><true/>
            </dict></plist>
            """
            try? fm.createDirectory(atPath: (plistPath as NSString).deletingLastPathComponent,
                                    withIntermediateDirectories: true)
            try? plist.write(toFile: plistPath, atomically: true, encoding: .utf8)
            shell("launchctl load \(plistPath) 2>/dev/null")
        }
    }

    @objc private func menuOpenRepo()   { NSWorkspace.shared.open(URL(fileURLWithPath: ideasDir)) }
    @objc private func menuOpenLog()    { NSWorkspace.shared.open(URL(fileURLWithPath: logFile)) }
    @objc private func menuOpenGitHub() {
        var url = shell("git remote get-url origin", cwd: ideasDir)
        url = url.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
                 .replacingOccurrences(of: ".git", with: "")
        if let u = URL(string: url) { NSWorkspace.shared.open(u) }
    }

    // MARK: 同步

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Double(pollMinutes) * 60,
                                     repeats: true) { [weak self] _ in
            self?.runSync()
        }
    }

    private func runSync(force: Bool = false) {
        guard !busy else { return }
        busy = true
        statusLine = "同步中…"
        detailLine = ""
        setIcon("arrow.triangle.2.circlepath", label: "同步中")

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/bash")
        p.arguments = force ? [syncScript, "--force"] : [syncScript]
        p.currentDirectoryURL = URL(fileURLWithPath: ideasDir)
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        running = p

        // 边跑边把 STATUS 行显示出来
        var buffer = ""
        var result = ""
        pipe.fileHandleForReading.readabilityHandler = { [weak self] fh in
            guard let text = String(data: fh.availableData, encoding: .utf8), !text.isEmpty else { return }
            buffer += text
            for line in buffer.components(separatedBy: "\n") {
                if line.hasPrefix("STATUS: ") {
                    let s = String(line.dropFirst(8))
                    DispatchQueue.main.async { self?.statusLine = s }
                } else if line.hasPrefix("RESULT: ") {
                    result = String(line.dropFirst(8))
                }
            }
            if let last = buffer.components(separatedBy: "\n").last { buffer = last }
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
            statusLine = "无法启动同步脚本"
            setIcon("exclamationmark.triangle", label: "出错")
        }
    }

    private func finish(_ result: String) {
        busy = false
        running = nil
        refreshAhead()

        let parts = result.components(separatedBy: "|")
        let code = parts.first ?? "error"
        let msg  = parts.count > 1 ? parts[1] : "未知结果"

        statusLine = msg
        detailLine = "上次同步 " + DateFormatter.localizedString(
            from: Date(), dateStyle: .none, timeStyle: .short)

        switch code {
        case "noop":
            setIcon("lightbulb")
        case "pushed", "updated":
            setIcon("checkmark.circle")
            notify("IdeaSync", msg)
        case "awaiting":
            setIcon("exclamationmark.circle", label: "待推送")
            notify("IdeaSync · 等待推送", msg)
        case "error":
            setIcon("exclamationmark.triangle", label: "出错")
            notify("IdeaSync · 出错", msg)
        default:
            setIcon("lightbulb")
        }
    }

    private func refreshAhead() {
        DispatchQueue.global().async {
            let n = shell("git rev-list --count @{u}..HEAD 2>/dev/null", cwd: ideasDir)
            DispatchQueue.main.async { self.aheadCount = Int(n) ?? 0 }
        }
    }

    // MARK: 配置读写

    private func readConf(_ key: String) -> String {
        guard let text = try? String(contentsOfFile: confFile, encoding: .utf8) else { return "" }
        for line in text.components(separatedBy: .newlines) {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("\(key)=") {
                return String(t.dropFirst(key.count + 1))
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
            }
        }
        return ""
    }

    private func writeConf(_ key: String, _ value: String) {
        guard var text = try? String(contentsOfFile: confFile, encoding: .utf8) else { return }
        var lines = text.components(separatedBy: .newlines)
        var found = false
        for i in lines.indices {
            if lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("\(key)=") {
                lines[i] = "\(key)=\(value)"
                found = true
            }
        }
        if !found { lines.append("\(key)=\(value)") }
        text = lines.joined(separator: "\n")
        try? text.write(toFile: confFile, atomically: true, encoding: .utf8)
    }
}

// MARK: - 启动

let app = NSApplication.shared
let delegate = IdeaSync()
app.delegate = delegate
app.setActivationPolicy(.accessory)     // 只在菜单栏，不占 Dock
app.run()
