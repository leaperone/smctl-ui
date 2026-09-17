# 项目指引

只记录本项目专属约束。通用规则由 ~/.agents/AGENTS.md 提供。

- 只 import `SMCtlClient` 与 `SMCtlProtocol`。禁止 import `SMCtlDaemonCore`。
- 策略留在 `smctld`。菜单栏通过 `DaemonClient` 读写 ping、电池状态、maintain/charging，以及风扇 profile（`auto` / `quiet` / `full`，回 auto 走 `setFanProfile` / `setFanAuto`）。不提供手动 RPM。
- `SMCtlClient` / `SMCtlProtocol` 通过 `Vendor/` 符号链接钉住 smctl 源码（sibling `../smctl`，或 `scripts/pin-smctl.sh` 拉的 `.deps/smctl`）。禁止 import `SMCtlDaemonCore`。不要改成整个 smctl package。
