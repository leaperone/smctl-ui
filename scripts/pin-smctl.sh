#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
vendor="$root/Vendor"
mkdir -p "$vendor"

url="https://github.com/leaperone/smctl.git"
ref="${SMCTL_REF:-main}"
dest="$root/.deps/smctl"

relpath() {
  python3 -c 'import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$1" "$2"
}

link_vendor() {
  local smctl_src="$1"
  if [[ ! -d "$smctl_src/SMCtlClient" || ! -d "$smctl_src/SMCtlProtocol" ]]; then
    echo "smctl sources missing SMCtlClient/SMCtlProtocol: $smctl_src" >&2
    rm -f "$vendor/SMCtlClient" "$vendor/SMCtlProtocol"
    exit 1
  fi
  ln -sfn "$(relpath "$smctl_src/SMCtlClient" "$vendor")" "$vendor/SMCtlClient"
  ln -sfn "$(relpath "$smctl_src/SMCtlProtocol" "$vendor")" "$vendor/SMCtlProtocol"
  echo "Pinned Vendor -> $smctl_src"
}

if [[ -n "${SMCTL_PATH:-}" ]]; then
  link_vendor "$(cd "${SMCTL_PATH}" && pwd)/Sources"
  exit 0
fi

if [[ -d "$dest/Sources/SMCtlClient" && -d "$dest/Sources/SMCtlProtocol" && -z "${SMCTL_REFRESH:-}" ]]; then
  link_vendor "$dest/Sources"
  exit 0
fi

mkdir -p "$root/.deps"
if [[ ! -d "$dest/.git" ]]; then
  git clone --depth 1 --branch "$ref" "$url" "$dest"
else
  git -C "$dest" remote set-url origin "$url"
  git -C "$dest" fetch --depth 1 origin "$ref"
  git -C "$dest" checkout --detach FETCH_HEAD
fi
link_vendor "$dest/Sources"
