#!/usr/bin/env bash
# Ideas 仓库的 agent 同步大脑
#
# 被菜单栏 app 定时调用，也可以手动跑：
#   ./agent-sync.sh          正常同步
#   ./agent-sync.sh --force  即使没有新提交也让 agent 复查一遍
#   ./agent-sync.sh --check  只看远端有没有新东西，不做任何改动
#
# 流程：fetch → 有新提交则 pull → 找出 projects/ 下变了什么 →
#       交给 agent 更新 _INDEX.md 与 PROJECTS.md → 提交 →（可选）推送
#
# 输出约定：每行 "STATUS: ..." 给 app 显示，最后一行 "RESULT: <code>|<摘要>"
#   code ∈ noop | remote | updated | pushed | awaiting | error

set -uo pipefail

IDEAS_DIR="${IDEAS_DIR:-$HOME/Ideas}"
SYNC_DIR="$IDEAS_DIR/sync"
CONF="$SYNC_DIR/agent.conf"
LOG="$SYNC_DIR/agent-sync.log"

# ---- 默认配置，可被 agent.conf 覆盖 ----
AUTO_PUSH=0                                  # 1 = agent 改完直接推；0 = 等你在菜单里点确认
MODEL="claude-sonnet-5"
MAX_FILES=25                                 # 单次交给 agent 的文件数上限
[ -f "$CONF" ] && . "$CONF"

FORCE=0; CHECK_ONLY=0
for a in "$@"; do
  case "$a" in
    --force) FORCE=1 ;;
    --check) CHECK_ONLY=1 ;;
  esac
done

say()  { echo "STATUS: $*"; echo "[$(date '+%F %T')] $*" >> "$LOG"; }
done_() { echo "RESULT: $1|$2"; echo "[$(date '+%F %T')] RESULT $1 — $2" >> "$LOG"; exit 0; }
die()  { echo "RESULT: error|$1"; echo "[$(date '+%F %T')] ERROR $1" >> "$LOG"; exit 1; }

cd "$IDEAS_DIR" 2>/dev/null || die "找不到仓库 $IDEAS_DIR"
git rev-parse --git-dir >/dev/null 2>&1 || die "$IDEAS_DIR 不是 git 仓库"

# ---- 互斥锁 ----
# 定时轮询和手工操作撞在一起会把 rebase 搅乱（真踩过），所以两道防护：
#   ① 同一时刻只允许一个 agent-sync 在跑
#   ② 工作区不干净 / 有未完成的 rebase 时直接跳过本轮，绝不硬来
LOCKDIR="$SYNC_DIR/.lock"
if ! mkdir "$LOCKDIR" 2>/dev/null; then
  if [ -f "$LOCKDIR/pid" ] && kill -0 "$(cat "$LOCKDIR/pid" 2>/dev/null)" 2>/dev/null; then
    done_ noop "已有同步在进行，跳过本轮"
  fi
  rm -rf "$LOCKDIR"
  mkdir "$LOCKDIR" 2>/dev/null || done_ noop "无法获取锁，跳过本轮"
fi
echo $$ > "$LOCKDIR/pid"
trap 'rm -rf "$LOCKDIR"' EXIT INT TERM

if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
  done_ noop "仓库有未完成的 rebase，需你手动处理后再同步"
fi

if [ -n "$(git status --porcelain)" ]; then
  done_ noop "工作区有未提交改动，跳过本轮（避免与手工操作冲突）"
fi

# ---- 定位 claude CLI ----
CLAUDE="$(command -v claude 2>/dev/null)"
if [ -z "$CLAUDE" ]; then
  CLAUDE="$(ls -d "$HOME"/.vscode/extensions/anthropic.claude-code-*/resources/native-binary/claude 2>/dev/null | sort -V | tail -1)"
fi
[ -x "${CLAUDE:-}" ] || die "找不到 claude CLI"

# ---- 看远端 ----
say "检查远端…"
git fetch -q origin 2>/dev/null || die "git fetch 失败（网络或认证问题）"

BEFORE="$(git rev-parse HEAD)"
UPSTREAM="$(git rev-parse '@{u}' 2>/dev/null)" || die "当前分支没有上游分支"

if [ "$CHECK_ONLY" = "1" ]; then
  n="$(git rev-list --count HEAD..'@{u}' 2>/dev/null || echo 0)"
  a="$(git rev-list --count '@{u}'..HEAD 2>/dev/null || echo 0)"
  [ "$n" -gt 0 ] && done_ remote "远端有 $n 个新提交"
  [ "$a" -gt 0 ] && done_ awaiting "本地有 $a 个提交未推送"
  done_ noop "已是最新"
fi

# ---- 拉取 ----
# 只在「落后于远端」时才拉；单纯领先（有未推送的提交）不算有新东西
BEHIND="$(git rev-list --count HEAD..'@{u}' 2>/dev/null || echo 0)"
if [ "$BEHIND" -gt 0 ]; then
  say "拉取 $BEHIND 个新提交…"
  git pull -q --rebase 2>/dev/null || die "git pull 失败（可能有冲突，需手动处理）"
else
  # 顶层有待入库的新项目文件夹时，即使没有新提交也要继续往下走
  HAS_INTAKE=0
  for d in */; do
    case " projects sync archive app node_modules " in *" ${d%/} "*) continue ;; esac
    compgen -G "${d%/}/*.md" >/dev/null 2>&1 && HAS_INTAKE=1 && break
  done
  if [ "$FORCE" = "0" ] && [ "$HAS_INTAKE" = "0" ]; then
    done_ noop "无新提交"
  fi
  [ "$HAS_INTAKE" = "1" ] && say "无新提交，但发现待入库的项目文件夹"
fi

AFTER="$(git rev-parse HEAD)"
DATE="$(date +%F)"

# ---- 新项目入库 ----
# 约定：新项目直接推一个顶层文件夹上来（如 capsec-strain-invariance/），
# 这里按文件名把它们分流进 projects/<名>/{tech,progress}/ 并加日期前缀。
# 移动由脚本做（确定性），agent 只负责写索引 —— 所以 agent 不需要 Bash 权限。
INTAKE=""
RESERVED=" projects sync archive app node_modules "
for d in */; do
  name="${d%/}"
  case "$RESERVED" in *" $name "*) continue ;; esac
  compgen -G "$name/*.md" >/dev/null 2>&1 || continue

  # 上传的文件夹常带 -docs 后缀（avo-redteam-docs），去掉后才能对上已有的项目目录
  proj="${name%-docs}"

  say "发现新项目文件夹 $name，归档到 projects/$proj/"
  mkdir -p "projects/$proj/tech" "projects/$proj/progress"

  for f in "$name"/*.md; do
    base="$(basename "$f")"
    lower="$(echo "$base" | tr '[:upper:]' '[:lower:]')"
    case "$lower" in
      *progress*|*status*|*进度*) sub=progress ;;
      *)                          sub=tech ;;
    esac
    # 去掉 01- 这类序号前缀；README 统一叫 overview
    clean="$(echo "$base" | sed -E 's/^[0-9]{2}-//')"
    [ "$lower" = "readme.md" ] && clean="overview.md"
    git mv "$f" "projects/$proj/$sub/$DATE-$clean" 2>/dev/null \
      || mv "$f" "projects/$proj/$sub/$DATE-$clean"
  done

  rmdir "$name" 2>/dev/null || true
  INTAKE="$INTAKE $proj"
done

# ---- 找出要交给 agent 的文档 ----
if [ "$BEFORE" != "$AFTER" ]; then
  CHANGED="$(git diff --name-only "$BEFORE" "$AFTER" -- projects/ \
             | grep -vE '/_INDEX\.md$' || true)"
else
  CHANGED=""
fi

# 刚入库的新项目文件也要一起交给 agent
if [ -n "$INTAKE" ]; then
  for name in $INTAKE; do
    CHANGED="$CHANGED
$(git ls-files "projects/$name" | grep -vE '/_INDEX\.md$' || true)"
  done
fi

# 没有增量但要求强制复查时，把全部文档都交上去
if [ -z "$(echo "$CHANGED" | grep -c . )" ] || [ "$(echo "$CHANGED" | grep -c .)" = "0" ]; then
  [ "$FORCE" = "1" ] && CHANGED="$(git ls-files projects/ | grep -vE '/_INDEX\.md$' || true)"
fi

CHANGED="$(echo "$CHANGED" | grep -v '^\s*$' || true)"

if [ -z "$CHANGED" ]; then
  done_ updated "已拉取新提交，但 projects/ 下无文档变化"
fi

COUNT="$(echo "$CHANGED" | grep -c .)"
if [ "$COUNT" -gt "$MAX_FILES" ]; then
  say "变化文件 $COUNT 个，超过上限 $MAX_FILES，只处理前 $MAX_FILES 个"
  CHANGED="$(echo "$CHANGED" | head -n "$MAX_FILES")"
  COUNT="$MAX_FILES"
fi

say "发现 $COUNT 个文档变化，交给 agent 分析…"

# ---- 交给 agent ----
PROMPT="你是这个 idea/项目管理仓库的文档管理 agent。仓库根目录就是当前工作目录。

以下文档刚刚有更新：
$CHANGED

请完成：
1. 读完这些文档。
2. 如果某个项目**还没有 \`_INDEX.md\`**（新入库的项目），照
   \`sync/_INDEX-template.md\` 的结构新建一份，并在 \`PROJECTS.md\` 里补上该项目的条目
   （若已有同名条目则补全它的「文档索引」链接，不要重复添加）。
3. 更新对应的 \`projects/<项目名>/_INDEX.md\`：
   - 表格里补上或修订每份文档的摘要（一两句话，说清这份文档到底讲了什么）
   - 进度类文档要填「与上一份的差异」一栏：哪些事项在推进、哪些反复延期、
     哪些描述与之前矛盾、哪些承诺没兑现
   - 「需要你注意的」一节写你发现的真问题：设计漏洞、证据强度不足、
     前后不一致、单点阻塞。没发现就写「无」，不要为凑数编问题
   - 更新顶部的「最近一次收到文档」和「当前节奏」
4. 更新 \`PROJECTS.md\` 里该项目的 **断点**、**下一步**、**更新** 日期。
   「下一步」必须具体到能立刻动手，不要写「继续推进」这种空话。
5. 如果多个项目的文档之间有可以互相借鉴的地方，写进相关项目的索引里。

约束：
- **不要修改 \`tech/\` 和 \`progress/\` 下的原始文档** —— 那是别人交上来的，只读。
- 不要新建 _INDEX.md 之外的文件。
- 全部用中文写。

最后用 3-5 行中文总结你改了什么、发现了什么值得注意的。"

OUT="$("$CLAUDE" -p "$PROMPT" \
        --model "$MODEL" \
        --permission-mode acceptEdits \
        --allowedTools Read Edit Write Glob Grep \
        --disallowedTools Bash \
        --add-dir "$IDEAS_DIR" 2>&1)"
RC=$?

{ echo "----- agent 输出 $(date '+%F %T') -----"; echo "$OUT"; } >> "$LOG"
[ $RC -ne 0 ] && die "agent 执行失败（详见 agent-sync.log）"

# ---- 提交 ----
if git diff --quiet && git diff --cached --quiet; then
  done_ updated "agent 分析完毕，认为无需改动索引"
fi

# 注意：不能用 cut -c —— macOS 上它按字节切，会把中文截成半个字符导致 git 报 UTF-8 警告
SUMMARY="$(echo "$OUT" | grep -v '^\s*$' | tail -5 | tr '\n' ' ' \
           | python3 -c 'import sys; print(sys.stdin.read()[:300])' 2>/dev/null \
           || echo "$OUT" | tail -3 | tr '\n' ' ')"
git add -A
git commit -qm "agent: 更新 $COUNT 份文档的索引与断点" -m "$SUMMARY" || die "提交失败"
say "已提交"

# ---- 推送 ----
if [ "$AUTO_PUSH" = "1" ]; then
  say "推送中…"
  git push -q 2>/dev/null || die "推送失败（本地已提交，可稍后手动 push）"
  done_ pushed "已分析 $COUNT 份文档并推送"
else
  done_ awaiting "已分析 $COUNT 份文档并本地提交，等你确认推送"
fi
