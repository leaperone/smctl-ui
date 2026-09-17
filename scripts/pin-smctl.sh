#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
vendor="$root/Vendor"
mkdir -p "$vendor"

relpath() {
  python3 -c 'import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$1" "$2"
}

link_vendor() {
  local smctl_src="$1"
  if [[ ! -d "$smctl_src/SMCtlClient" || ! -d "$smctl_src/SMCtlProtocol" ]]; then
    echo "smctl sources missing SMCtlClient/SMCtlProtocol: $smctl_src" >&2
    exit 1
  fi
  ln -sfn "$(relpath "$smctl_src/SMCtlClient" "$vendor")" "$vendor/SMCtlClient"
  ln -sfn "$(relpath "$smctl_src/SMCtlProtocol" "$vendor")" "$vendor/SMCtlProtocol"
  echo "Pinned Vendor -> $smctl_src"
}

if [[ -n "${SMCTL_PATH:-}" ]]; then
  link_vendor "$(cd "${SMCTL_PATH}" && pwd)/Sources"
elif [[ -d "$root/../smctl/Sources/SMCtlClient" ]]; then
  link_vendor "$(cd "$root/../smctl/Sources" && pwd)"
else
  dest="$root/.deps/smctl"
  ref="${SMCTL_REF:-main}"
  if [[ ! -d "$dest/.git" ]]; then
    git clone --depth 1 --branch "$ref" https://github.com/leaperone/smctl.git "$dest"
  else
    git -C "$dest" fetch --depth 1 origin "$ref"
    git -C "$dest" checkout --detach FETCH_HEAD
  fi
  link_vendor "$dest/Sources"
fi
