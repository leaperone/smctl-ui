#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

swift build -c debug --product SMCtlMenuBar
bin_dir="$(swift build -c debug --show-bin-path)"
app="$root/.build/SMCtlMenuBar.app"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin_dir/SMCtlMenuBar" "$app/Contents/MacOS/SMCtlMenuBar"
cp "$root/Info.plist" "$app/Contents/Info.plist"
echo "$app"
