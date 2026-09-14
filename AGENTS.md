# 项目指引

只记录本项目专属约束。通用规则由 ~/.agents/AGENTS.md 提供。

- 只 import `SMCtlClient` 与 `SMCtlProtocol`。禁止 import `SMCtlDaemonCore`。
- 策略留在 `smctld`。菜单栏通过 `DaemonClient` 读写 ping、电池状态与 maintain/charging。
- `SMCtlClient` 在 smctl#21 合并前通过 `Vendor/SMCtlClient` 与 `Vendor/SMCtlProtocol` 符号链接钉住 extract worktree，不要改成整个 smctl package。
