#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

config="${1:-debug}"
case "$config" in
  debug|release) ;;
  *)
    echo "usage: $0 [debug|release]" >&2
    exit 2
    ;;
esac

if [[ ! -e Vendor/SMCtlClient/DaemonClient.swift ]]; then
  ./scripts/pin-smctl.sh
fi

swift build -c "$config" --product SMCtlMenuBar
bin_dir="$(swift build -c "$config" --show-bin-path)"
app="$root/.build/SMCtlMenuBar.app"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin_dir/SMCtlMenuBar" "$app/Contents/MacOS/SMCtlMenuBar"
cp "$root/Info.plist" "$app/Contents/Info.plist"
echo "$app"
