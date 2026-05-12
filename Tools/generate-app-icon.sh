#!/bin/bash
# Regenerate App/Resources/Assets.xcassets/AppIcon.appiconset from the SF Symbol
# "fanblades". Idempotent — safe to re-run any time.
set -euo pipefail

cd "$(dirname "$0")/.."
CATALOG="App/Resources/Assets.xcassets"
SET="$CATALOG/AppIcon.appiconset"
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

swift Tools/generate-app-icon.swift "$TMP/icon-1024.png"

declare -a SPECS=(
    "16   icon_16x16.png"
    "32   icon_16x16@2x.png"
    "32   icon_32x32.png"
    "64   icon_32x32@2x.png"
    "128  icon_128x128.png"
    "256  icon_128x128@2x.png"
    "256  icon_256x256.png"
    "512  icon_256x256@2x.png"
    "512  icon_512x512.png"
    "1024 icon_512x512@2x.png"
)

mkdir -p "$SET"
for spec in "${SPECS[@]}"; do
    px=${spec%% *}; name=${spec##* }
    sips -s format png -z "$px" "$px" "$TMP/icon-1024.png" --out "$SET/$name" >/dev/null
done

cat > "$CATALOG/Contents.json" <<'JSON'
{
  "info": {
    "author": "xcode",
    "version": 1
  }
}
JSON

cat > "$SET/Contents.json" <<'JSON'
{
  "images": [
    {
      "filename": "icon_16x16.png",
      "idiom": "mac",
      "scale": "1x",
      "size": "16x16"
    },
    {
      "filename": "icon_16x16@2x.png",
      "idiom": "mac",
      "scale": "2x",
      "size": "16x16"
    },
    {
      "filename": "icon_32x32.png",
      "idiom": "mac",
      "scale": "1x",
      "size": "32x32"
    },
    {
      "filename": "icon_32x32@2x.png",
      "idiom": "mac",
      "scale": "2x",
      "size": "32x32"
    },
    {
      "filename": "icon_128x128.png",
      "idiom": "mac",
      "scale": "1x",
      "size": "128x128"
    },
    {
      "filename": "icon_128x128@2x.png",
      "idiom": "mac",
      "scale": "2x",
      "size": "128x128"
    },
    {
      "filename": "icon_256x256.png",
      "idiom": "mac",
      "scale": "1x",
      "size": "256x256"
    },
    {
      "filename": "icon_256x256@2x.png",
      "idiom": "mac",
      "scale": "2x",
      "size": "256x256"
    },
    {
      "filename": "icon_512x512.png",
      "idiom": "mac",
      "scale": "1x",
      "size": "512x512"
    },
    {
      "filename": "icon_512x512@2x.png",
      "idiom": "mac",
      "scale": "2x",
      "size": "512x512"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
JSON

echo "wrote $SET ($(ls "$SET"/*.png | wc -l | tr -d ' ') images plus Contents.json)"
