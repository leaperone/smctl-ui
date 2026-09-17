# smctl-ui

[![CI](https://github.com/leaperone/smctl-ui/actions/workflows/ci.yml/badge.svg)](https://github.com/leaperone/smctl-ui/actions/workflows/ci.yml)

SwiftUI `MenuBarExtra` companion for [smctl](https://github.com/leaperone/smctl).

Depends on `SMCtlClient` and `SMCtlProtocol` from smctl. Policy stays in `smctld`. The extra shows charge percent, the configured limit, and fan RPM (or the SMC no-fans message). It sends maintain (`80`, `70-80`, `stop`), charging on/off, and fan profiles (`auto`, `quiet`, `full`, plus return-to-auto) through `DaemonClient`. Manual RPM entry is not in this menu. Thermal guard stays active on the daemon.

## Path pin (stack)

`Vendor/SMCtlClient` and `Vendor/SMCtlProtocol` are symlinks onto smctl's `SMCtlClient` and `SMCtlProtocol` sources. Do not depend on the whole smctl package.

```bash
./scripts/pin-smctl.sh
```

The script prefers a sibling `../smctl` checkout when it already has `Sources/SMCtlClient`. Otherwise it clones [leaperone/smctl](https://github.com/leaperone/smctl) into `.deps/smctl`. CI does the same with `SMCTL_PATH=.deps/smctl`.

## Build and run

```bash
./scripts/pin-smctl.sh
swift build --product SMCtlMenuBar
./scripts/bundle-app.sh
open .build/SMCtlMenuBar.app
```

`Info.plist` sets `LSUIElement` so the app stays out of the Dock. `./scripts/bundle-app.sh release` builds the release `.app`.

## Tests

```bash
./scripts/pin-smctl.sh
swift test
```

Needs a full Xcode toolchain (`xcode-select` pointing at Xcode), not Command Line Tools alone.

## CI/CD

GitHub Actions on `main` and pull requests pins smctl, then runs `swift build`, `swift test`, a release build, and uploads `SMCtlMenuBar.app`. Push a `v*` tag to cut a GitHub Release with an unsigned `.app` zip.
