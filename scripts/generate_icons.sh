#!/usr/bin/env bash
set -euo pipefail

APP_DIR="AltitudeNow"
OUT_DIR="$APP_DIR/Resources/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$OUT_DIR"

if command -v swift >/dev/null 2>&1 && [ "$(uname)" = "Darwin" ]; then
    swift scripts/IconGenerator.swift "$OUT_DIR/icon.png"
elif command -v convert >/dev/null 2>&1; then
    convert -size 1024x1024 \
      -define gradient:angle=180 \
      gradient:"#264653-#2A9D8F" \
      -alpha off \
      -fill 'rgba(255,255,255,0.85)' \
      -draw "polygon 80,820 360,420 540,640 720,300 944,820" \
      -fill white \
      -font Helvetica-Bold -pointsize 280 -gravity north \
      -annotate +0+120 "A" \
      "$OUT_DIR/icon.png"
else
    echo "[generate_icons] Neither swift (macOS) nor imagemagick found — skipping."
    exit 0
fi

cat > "$OUT_DIR/Contents.json" <<'JSON'
{
  "images" : [
    {
      "filename" : "icon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

echo "[generate_icons] wrote $OUT_DIR/icon.png"
