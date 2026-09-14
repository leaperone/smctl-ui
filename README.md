# smctl-ui

SwiftUI `MenuBarExtra` companion for [smctl](https://github.com/leaperone/smctl).

Depends on `SMCtlClient` and `SMCtlProtocol` from smctl. Policy stays in `smctld`. The extra shows charge percent and the configured limit, and sends maintain (`80`, `70-80`, `stop`) and charging on/off through `DaemonClient`.

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
