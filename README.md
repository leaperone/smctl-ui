# smctl-ui

SwiftUI `MenuBarExtra` companion for [smctl](https://github.com/leaperone/smctl).

Depends on `SMCtlClient` and `SMCtlProtocol` from smctl. Policy stays in `smctld`. The extra shows charge percent, the configured limit, and fan RPM (or the SMC no-fans message). It sends maintain (`80`, `70-80`, `stop`), charging on/off, and fan profiles (`auto`, `quiet`, `full`, plus return-to-auto) through `DaemonClient`. Manual RPM entry is not in this menu. Thermal guard stays active on the daemon.

## Path pin (stack)

`Vendor/SMCtlClient` and `Vendor/SMCtlProtocol` are symlinks into the local smctl `feat/smctl-client` worktree.

```text
../../../../smctl/.worktrees/feat-smctl-client/Sources/{SMCtlClient,SMCtlProtocol}
```

Retarget the symlinks after `SMCtlClient` lands on smctl `main`, or point them at a sibling `../smctl` checkout.

## Build and run

```bash
swift build --product SMCtlMenuBar
./scripts/bundle-app.sh
open .build/SMCtlMenuBar.app
```

`Info.plist` sets `LSUIElement` so the app stays out of the Dock.

## Tests

```bash
swift test
```

Needs a full Xcode toolchain (`xcode-select` pointing at Xcode), not Command Line Tools alone.
