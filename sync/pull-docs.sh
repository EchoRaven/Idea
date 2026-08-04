#!/usr/bin/env bash
# 从各服务器拉取项目文档到本地 _inbox/
#
#   ./pull-docs.sh              拉取全部项目
#   ./pull-docs.sh virtue-guard 只拉指定项目
#   ./pull-docs.sh -n           dry-run，只看会拉什么，不实际下载
#
# 新拉到的文件会记进 sync/new-files.log，Claude 读这个文件就知道要处理哪些。

set -uo pipefail

IDEAS_DIR="${IDEAS_DIR:-$HOME/Ideas}"
SYNC_DIR="$IDEAS_DIR/sync"
CONF="$SYNC_DIR/sources.conf"
NEWLOG="$SYNC_DIR/new-files.log"
RUNLOG="$SYNC_DIR/last-run.log"

DRY=""
FILTER=""
for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY="--dry-run" ;;
    -*) echo "未知选项: $arg" >&2; exit 2 ;;
    *)  FILTER="$arg" ;;
  esac
done

[ -f "$CONF" ] || { echo "找不到配置文件: $CONF" >&2; exit 1; }

# 只拉文档类文件，明确排除大文件目录
RSYNC_FILTERS=(
  --include='*/'
  --include='*.md'   --include='*.txt'   --include='*.pdf'
  --include='*.docx' --include='*.doc'   --include='*.tex'
  --include='*.ipynb' --include='*.csv'  --include='*.xlsx'
  --include='*.png'  --include='*.jpg'   --include='*.svg'
  --include='README*' --include='CHANGELOG*'
  --exclude='.git/'  --exclude='node_modules/' --exclude='__pycache__/'
  --exclude='wandb/' --exclude='checkpoints/'  --exclude='ckpt/'
  --exclude='data/'  --exclude='datasets/'     --exclude='logs/'
  --exclude='*'
)

STAMP="$(date '+%Y-%m-%d %H:%M')"
: > "$RUNLOG"
NEW_COUNT=0
FAIL_COUNT=0
SRC_COUNT=0

echo "=== 拉取开始 $STAMP ${DRY:+(dry-run)} ==="

while IFS='|' read -r proj host rpath note; do
  # 跳过注释和空行
  proj="$(echo "${proj:-}" | xargs)"
  [ -z "$proj" ] && continue
  case "$proj" in \#*) continue ;; esac

  host="$(echo "${host:-}" | xargs)"
  rpath="$(echo "${rpath:-}" | xargs)"
  [ -z "$host" ] || [ -z "$rpath" ] && { echo "⚠ 配置不完整，跳过: $proj"; continue; }

  [ -n "$FILTER" ] && [ "$FILTER" != "$proj" ] && continue

  SRC_COUNT=$((SRC_COUNT+1))
  dest="$IDEAS_DIR/projects/$proj/_inbox"
  mkdir -p "$dest"

  echo "→ $proj  ←  $host:$rpath"

  out="$(rsync -az --itemize-changes --prune-empty-dirs \
          --timeout=30 -e 'ssh -o ConnectTimeout=15 -o BatchMode=yes' \
          $DRY "${RSYNC_FILTERS[@]}" \
          "$host:$rpath/" "$dest/" 2>&1)"
  rc=$?

  if [ $rc -ne 0 ]; then
    echo "   ✗ 失败 (rc=$rc): $(echo "$out" | tail -2 | tr '\n' ' ')"
    echo "FAIL|$proj|$host:$rpath|$out" >> "$RUNLOG"
    FAIL_COUNT=$((FAIL_COUNT+1))
    continue
  fi

  # itemize-changes 里 >f 开头的是实际传输的文件
  files="$(echo "$out" | grep -E '^>f' | sed 's/^[^ ]* //')"
  if [ -n "$files" ]; then
    n=$(echo "$files" | grep -c . )
    echo "   ✓ 新增/更新 $n 个文件"
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      echo "$STAMP|$proj|$host|$f" >> "$NEWLOG"
      echo "     · $f"
    done <<< "$files"
    NEW_COUNT=$((NEW_COUNT+n))
  else
    echo "   · 无变化"
  fi
done < "$CONF"

echo
if [ "$SRC_COUNT" -eq 0 ]; then
  echo "没有匹配的来源。先编辑 $CONF 填入你的项目。"
  exit 0
fi
echo "=== 完成：$SRC_COUNT 个来源，$NEW_COUNT 个新文件，$FAIL_COUNT 个失败 ==="
[ "$NEW_COUNT" -gt 0 ] && echo "下一步：在 Claude Code 里说「处理一下新文档」"
exit 0
