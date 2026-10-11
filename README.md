# flake

面向 x86_64 Linux VPS 的 NixOS 配置，使用锁定的 NixOS 26.05 和 Home Manager。机器选择需要的功能，系统配置放在 `modules/`，用户软件放在 `home/`。

## 从哪里开始读

1. [flake.nix](flake.nix)：声明依赖、列出机器、提供安装与开发工具。
2. [machines/vps/default.nix](machines/vps/default.nix)：选择系统模块，设置主机名、平台和时区。
3. [machines/vps/home.nix](machines/vps/home.nix)：选择这台机器的用户软件。
4. 跟随 `imports` 打开相应模块，查看具体选项。Nix 基本语法见[结构说明](docs/architecture.md)。

| 想修改什么 | 修改位置 |
| --- | --- |
| 依赖版本、增加机器入口 | `flake.nix`；`flake.lock` 由 Nix 更新 |
| 管理员与 SSH 公钥 | `users.nix`（选项定义在 `modules/nixos/admin.nix`） |
| 主机名、时区、系统功能 | `machines/<name>/default.nix` |
| 本机选择哪些用户软件 | `machines/<name>/home.nix` |
| 软件的具体设置与 dotfiles | `home/shell.nix`、`home/cli/`、`home/programs/` |
| 共用系统设置与外部模块接入 | `modules/nixos/` |
| 硬件与目标磁盘 | `machines/<name>/hardware-configuration.nix`、`storage.nix` |
| 原生 Xray 配置（加密 JSON） | `secrets/xray.json`，用 `sops edit` 修改；加密公钥在 `.sops.yaml` |
| 代理服务、端口与开关 | `modules/nixos/services/proxy.nix`；机器中设置 `local.proxy.*` |
| CI 与本地检查 | `flake.nix` 的 `checks`，测试文件在 `tests/` |

## 首次使用

```bash
git clone https://github.com/Tao-Boy/flake.git
cd flake
nix develop
```

安装前准备四项：

1. 在 `users.nix` 填写 `.pub` 文件的完整 SSH 公钥，默认管理员为 `tau`。
2. 核对 `machines/vps/storage.nix` 的目标整盘，默认为 `/dev/vda`。
3. 保留适用的 QEMU 硬件模板，或按[安装说明](docs/deployment.md)显式让 nixos-anywhere 生成硬件配置。网络默认使用 DHCP / IPv6 RA；服务商要求静态地址时在机器中补充。
4. 按[代理说明](docs/proxy.md)生成 age 密钥、填写 `.sops.yaml`，用 `sops` 从示例创建并编辑完整的 Xray JSON，填写真实节点。私钥留在仓库外，部署到目标系统。

```bash
git add users.nix machines/vps .sops.yaml secrets/xray.json
nix flake check --no-build --no-write-lock-file
```

**首次安装会清空指定磁盘。** 核对磁盘并备份后，按[安装与远程更新](docs/deployment.md)执行完整命令，其中包含 age 私钥部署。国内网络下的 LiveCD 临时代理、工具预复制和本机安装流程见[代理说明](docs/proxy.md)。

## 日常修改

```bash
nix develop
nix fmt
nix flake check --no-build --no-write-lock-file
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 验证网络与第二个 SSH 会话后保存为启动默认配置。
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
```

`.#vps` 选择 flake 中的 `nixosConfigurations.vps`。新增 Nix 文件先 `git add`，再检查或重建。默认启用本地 Xray；Bash 中用 `proxy-on` / `proxy-off` 在默认配置与 `proxy-off` 特化之间切换，同时更新当前终端和 Nix 守护进程，重启后恢复默认开启。

根目录 `/` 使用 tmpfs，重启清空；`/home` 使用默认 4 GiB 的 ext4 分区，`/nix` 使用剩余空间的 ext4 分区。SSH 主机密钥与 age 私钥保存在 `/nix/var/lib/`。数据库、系统容器和 ACME 等 `/var` 状态需要额外安排持久存储。已有分区不能通过普通重建转换。

CI 运行 flake 的 `checks`：格式与静态分析、构建机器及其 disko 脚本，并在 NixOS 虚拟机中验证代理监听和开关。详细说明：

- [配置结构与基本语法](docs/architecture.md)
- [定制配置与新增机器](docs/customization.md)
- [安装与远程更新](docs/deployment.md)
- [用户软件与软件源](docs/home-manager.md)
- [可选服务](docs/services.md)
- [Xray、加密凭据与 LiveCD](docs/proxy.md)
- [检查、回滚与备份](docs/operations.md)
