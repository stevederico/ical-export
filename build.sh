#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/ical-export.app"
BIN="$APP/Contents/MacOS/ical-export"
SDK="$(xcrun --show-sdk-path)"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
swiftc -parse-as-library -O \
  -target arm64-apple-macos14.0 \
  -sdk "$SDK" \
  -framework SwiftUI -framework EventKit -framework AppKit \
  -o "$BIN" \
  "$ROOT/ICalExport.swift"
chmod +x "$BIN"
codesign --force --sign - "$APP" >/dev/null
echo "built $APP"
