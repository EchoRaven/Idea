#!/usr/bin/env bash
# 编译 IdeaSync 并组装成 .app（不需要完整 Xcode，Command Line Tools 就够）
#
#   ./build.sh            编译到 ./IdeaSync.app
#   ./build.sh --install  编译并安装到 ~/Applications，然后启动

set -euo pipefail
cd "$(dirname "$0")"

APP="IdeaSync.app"
BUNDLE_ID="com.thb.ideasync"

echo "→ 编译…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O IdeaSync.swift -o "$APP/Contents/MacOS/IdeaSync" \
  -framework AppKit -target arm64-apple-macos13.0

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>IdeaSync</string>
  <key>CFBundleDisplayName</key><string>IdeaSync</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>IdeaSync</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

# 本地签名 —— 没有开发者证书也能跑，只是不能分发给别人
codesign --force --deep --sign - "$APP" 2>/dev/null && echo "→ 已本地签名" || echo "→ 跳过签名"

echo "✓ 编译完成：$(pwd)/$APP"

if [ "${1:-}" = "--install" ]; then
  DEST="$HOME/Applications"
  mkdir -p "$DEST"
  pkill -f "$DEST/$APP" 2>/dev/null || true
  rm -rf "${DEST:?}/$APP"
  cp -R "$APP" "$DEST/"
  echo "✓ 已安装到 $DEST/$APP"
  open "$DEST/$APP"
  echo "✓ 已启动 —— 看菜单栏右上角的托盘图标"
fi
