#!/usr/bin/env bash
# 把 Ideas 系统从 iCloud 迁移到 Google Drive
#
# 前置：已安装 Google Drive 桌面端并登录（挂载点会出现在 ~/Library/CloudStorage/）
#
#   ./migrate-to-gdrive.sh          检测环境并预览，不实际改动
#   ./migrate-to-gdrive.sh --go     执行迁移
#
# iCloud 上的原件不会删除，保留作为备份。

set -uo pipefail

OLD="${IDEAS_DIR:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/Ideas}"
GO=""
[ "${1:-}" = "--go" ] && GO=1

echo "=== 检测 Google Drive 挂载 ==="
# macOS 自带 bash 3.2，没有 mapfile，用兼容写法
MOUNTS=()
while IFS= read -r line; do
  [ -n "$line" ] && MOUNTS+=("$line")
done < <(ls -d "$HOME/Library/CloudStorage/GoogleDrive-"* 2>/dev/null)

if [ "${#MOUNTS[@]}" -eq 0 ]; then
  echo "✗ 没找到 Google Drive 挂载点。"
  echo
  echo "  请先安装并登录 Google Drive 桌面端："
  echo "    https://www.google.com/drive/download/"
  echo "  登录后会出现 ~/Library/CloudStorage/GoogleDrive-<邮箱>/"
  echo "  然后重新运行本脚本。"
  exit 1
fi

if [ "${#MOUNTS[@]}" -gt 1 ]; then
  echo "找到多个 Google 账号，请手动指定："
  for m in "${MOUNTS[@]}"; do echo "  - $m"; done
  echo "用法：GDRIVE_ROOT=<上面某一行> $0 --go"
  [ -z "${GDRIVE_ROOT:-}" ] && exit 1
  ROOT="$GDRIVE_ROOT"
else
  ROOT="${GDRIVE_ROOT:-${MOUNTS[0]}}"
fi

echo "✓ 挂载点：$ROOT"

# 我的云端硬盘的实际目录名随语言变化（My Drive / 我的云端硬盘）
MYDRIVE=""
for cand in "$ROOT/My Drive" "$ROOT/我的云端硬盘" "$ROOT/マイドライブ"; do
  [ -d "$cand" ] && MYDRIVE="$cand" && break
done
if [ -z "$MYDRIVE" ]; then
  echo "✗ 找不到「我的云端硬盘 / My Drive」目录。当前 $ROOT 下有："
  ls -1 "$ROOT" 2>/dev/null | sed 's/^/    /'
  exit 1
fi
echo "✓ 云端硬盘根目录：$MYDRIVE"

NEW="$MYDRIVE/Ideas"
echo
echo "=== 迁移计划 ==="
echo "  从：$OLD"
echo "  到：$NEW"
echo "  iCloud 原件保留不删"
echo
echo "同时会创建共享上传区（记得在 Drive 网页端把它分享给合作者）："
echo "  $MYDRIVE/项目文档上传/"

if [ -z "$GO" ]; then
  echo
  echo "--- 这是预览。确认无误后运行：$0 --go ---"
  exit 0
fi

echo
echo "=== 开始迁移 ==="
mkdir -p "$NEW" "$MYDRIVE/项目文档上传"
# 注意：macOS 15 自带的是 openrsync，不支持 --info=progress2
rsync -a --stats "$OLD/" "$NEW/" || { echo "✗ 复制失败"; exit 1; }
echo "✓ 文件已复制"

# 更新 .zshrc 里的 IDEAS_DIR
ZSHRC="$HOME/.zshrc"
if grep -q '^export IDEAS_DIR=' "$ZSHRC" 2>/dev/null; then
  cp "$ZSHRC" "$ZSHRC.bak-ideas"
  # 用 | 作分隔符避免路径里的斜杠冲突
  sed -i '' "s|^export IDEAS_DIR=.*|export IDEAS_DIR=\"$NEW\"|" "$ZSHRC"
  echo "✓ 已更新 ~/.zshrc 的 IDEAS_DIR（备份：$ZSHRC.bak-ideas）"
else
  echo "⚠ 未在 ~/.zshrc 找到 IDEAS_DIR，请手动设置为：$NEW"
fi

echo
echo "=== 完成 ==="
echo "运行 source ~/.zshrc 生效，然后 inboxq 验证。"
echo "iCloud 备份仍在：$OLD"
echo "确认一切正常后可以手动删除它。"
