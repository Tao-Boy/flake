# flake

面向 x86_64 Linux VPS 的模块化 NixOS 配置。系统使用锁定的 NixOS 26.05 与 Home Manager，精选终端工具来自独立锁定的 nixpkgs-unstable。系统配置与用户环境分别放在 `modules/nixos/` 和 `home/`；硬件配置是用户管理的普通 Nix 文件，网络默认通过 DHCP / IPv6 RA 获取地址、路由与 DNS。

## 目录与职责

| 目录或文件 | 职责 |
| --- | --- |
| `flake.nix`、`flake.lock` | 声明并锁定输入 |
| `machines/default.nix` | 机器清单，指定系统入口和用户软件选择入口 |
| `machines/vps/default.nix` | 本地配置入口、时区和系统兼容版本 |
| `machines/vps/hardware-configuration.nix` | 用户管理的硬件配置，可选择由安装器生成 |
| `machines/vps/storage.nix` | 选择存储布局、明确指定待安装的整块磁盘 |
| `modules/nixos/` | 系统核心、网络、安全、服务、存储模块 |
| `modules/home.nix` | 接入 Home Manager，引用 `home/` 中的配置 |
| `modules/disko.nix` | 接入 disko，由机器存储配置间接导入 |
| `home/default.nix` | 公共 Home Manager 兼容设置 |
| `home/shell/`、`home/cli/`、`home/programs/` | shell、按用途分类的工具、独立程序配置 |
| `machines/vps/home.nix` | 选择该机器启用的用户软件模块 |
| `outputs/default.nix` | 系统、安装器、格式化器和开发环境输出 |
| `users.nix` | 管理员身份与 SSH 公钥 |
| `docs/` | 定制、部署与运维说明 |

软件如何配置写在 `home/`，机器是否使用该软件写在 `machines/<name>/home.nix`。系统与用户配置通过本地文件显式导入，结构与参考项目见[结构说明](docs/architecture.md)。

## 最小配置与安装

```bash
git clone https://github.com/Tao-Boy/flake.git
cd flake
```

1. 在 `users.nix` 填写完整 SSH 公钥；默认管理员为 `tau`，UID 为 1000。
2. 在 `machines/vps/storage.nix` 核对目标整盘；默认为 `/dev/vda`，优先使用稳定的 by-id 路径。
3. 决定保留适用于 QEMU VPS 的硬件模板，或在安装时生成真实硬件配置。
4. 确认服务商支持 DHCP / IPv6 RA；静态网络在机器中补充[网络配置](docs/customization.md)。

```nix
# users.nix
{
  username = "tau";
  sshKeys = [ "ssh-ed25519 你的完整公钥 you@laptop" ];
}
```

新增 Nix 文件先 `git add`。填写真实公钥后检查：

```bash
nix flake check --no-build --no-write-lock-file
```

**安装会按 disko 布局清空目标磁盘。** 先备份数据并核对整盘。使用已准备好的硬件配置安装：

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER
```

若选择在安装时生成并替换硬件配置，显式添加上游参数：

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER \
  --generate-hardware-config nixos-generate-config ./machines/vps/hardware-configuration.nix
```

`install` 直接引用锁定的 `nixos-anywhere` 包。只有用户指定生成参数时，安装器才写入硬件配置；仓库求值不执行硬件探测，也不根据报告是否存在改变导入。生成完成后审查并提交 Nix 文件。此后重建使用已保存的配置。磁盘擦除目标仍由用户明确指定，静态网络参数按服务商要求填写。

## 存储与更新

| 路径 | 存储 | 重启后 |
| --- | --- | --- |
| `/` | tmpfs，上限为内存的 50% | 清空，系统配置重新生成 |
| `/nix` | Btrfs 子卷 | 保留软件、系统代际与 SSH 主机密钥 |
| `/home` | Btrfs 子卷 | 保留用户文件与 Home Manager 数据 |
| `/boot` | 512 MiB ESP | 保留启动文件 |

目录调整保留上述布局、管理员 UID、SSH 策略以及 `system.stateVersion` / `home.stateVersion`。旧 ext4 根不能通过重建自动转成此布局；`/var` 的数据库、系统容器和 ACME 状态仍需单独持久化。

```bash
nix develop
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 验证第二个 SSH 会话后持久化
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
```

CI 直接执行格式 / 静态检查、NixOS 求值、系统与 disko 脚本构建；Home Manager 随系统构建。仓库不保留测试目录或自定义 checks 输出。空公钥模板仅在 CI 工作区临时填入生成的公钥。

- [目录设计与迁移](docs/architecture.md)
- [定制与新增机器](docs/customization.md)
- [安装与更新](docs/deployment.md)
- [用户环境与软件源](docs/home-manager.md)
- [可选服务](docs/services.md)
- [检查与运维](docs/operations.md)
