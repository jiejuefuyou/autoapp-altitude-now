#!/usr/bin/env bash
set -euo pipefail

APP_DIR="AltitudeNow"
LETTER="A"
GRAD_FROM="#264653"
GRAD_TO="#2A9D8F"

OUT_DIR="$APP_DIR/Resources/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$OUT_DIR"

if ! command -v convert >/dev/null 2>&1; then
  echo "[generate_icons] ImageMagick (convert) not found — skipping icon generation."
  exit 0
fi

if convert -list font 2>/dev/null | grep -qE '^\s+Font: Helvetica-Bold'; then
  FONT="Helvetica-Bold"
elif convert -list font 2>/dev/null | grep -qE '^\s+Font: Helvetica'; then
  FONT="Helvetica"
else
  FONT="Arial-Bold"
fi

# Compose a placeholder icon: gradient backdrop + simple mountain silhouette + letter overlay.
convert -size 1024x1024 \
  -define gradient:angle=180 \
  gradient:"${GRAD_FROM}-${GRAD_TO}" \
  -alpha off \
  -fill 'rgba(255,255,255,0.85)' \
  -draw "polygon 80,820 360,420 540,640 720,300 944,820" \
  -fill white \
  -font "$FONT" \
  -pointsize 280 -gravity north \
  -annotate +0+120 "$LETTER" \
  "$OUT_DIR/icon.png"

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
