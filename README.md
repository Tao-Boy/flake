# flake

面向 x86_64 Linux VPS 的模块化 NixOS 配置。系统使用锁定的 NixOS 26.05 与 Home Manager，精选终端工具来自独立锁定的 nixpkgs-unstable。机器入口只声明角色、存储目标和本机差异，硬件由 `nixos-facter` 探测，普通网络通过 DHCP / IPv6 RA 获取地址、路由与 DNS。

## 目录与职责

| 目录或文件 | 职责 |
| --- | --- |
| `flake.nix`、`flake.lock` | 声明并锁定输入，不混入机器配置 |
| `machines/default.nix` | 机器清单；自动生成系统和每台机器的构建检查 |
| `machines/vps/default.nix` | 角色选择、时区和系统兼容版本 |
| `machines/vps/hardware.nix` | 接入同目录的自动探测报告 `facter.json` |
| `machines/vps/storage.nix` | 明确指定待安装的整块磁盘 |
| `machines/vps/home.nix` | 该机器的用户环境差异 |
| `profiles/nixos/`、`profiles/home/` | 组合常用功能，供机器选择 |
| `modules/nixos/` | 系统核心、网络、安全、服务、存储布局 |
| `modules/home/` | shell、通用工具、诊断、网络工具、独立程序配置 |
| `lib/` | 系统构造和探测报告接入逻辑 |
| `outputs/` | 包、开发环境和输出组装 |
| `users.nix` | 管理员身份与 SSH 公钥 |
| `tests/` | Nix 求值、质量、安装和重启测试 |
| `docs/` | 结构说明、定制、部署和运维 |

配置顺序为：`inputs → outputs → machines → profiles → modules`。不再维护 `hosts/`、`home/hosts/` 或独立 shell 脚本。结构参考 [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)、[ryan4yin/nix-config](https://github.com/ryan4yin/nix-config) 和 [hlissner/dotfiles](https://github.com/hlissner/dotfiles)，取其分层思路，保留原生 NixOS / Home Manager 选项。详细理由见[结构说明](docs/architecture.md)。

## 最小配置与安装

```bash
git clone https://github.com/Tao-Boy/flake.git
cd flake
```

1. 在 `users.nix` 填写完整 SSH 公钥；默认管理员为 `tau`，UID 为 1000。
2. 在 `machines/vps/storage.nix` 核对目标整盘；默认为 `/dev/vda`，优先使用稳定的 by-id 路径。
3. 确认服务商支持 DHCP / IPv6 RA；只有静态网络才需要在机器中补充[网络配置](docs/customization.md)。

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

**下列安装命令会按 disko 布局清空目标磁盘。** 先备份数据并核对整盘，再运行：

```bash
nix run .#install -- \
  --flake .#vps --target-host root@YOUR_SERVER \
  --generate-hardware-config nixos-facter ./machines/vps/facter.json
```

`install` 直接引用锁定的 `nixos-anywhere` 包，参数采用上游语法。安装器探测真实硬件后写入报告，再求值并构建系统；报告包含所需存储驱动、CPU 和虚拟化信息，NixOS 自动生成相应配置。缺少报告时仅使用上游 QEMU profile 作为模板 / VM 测试起点，正式安装应使用探测参数。安装后审查并提交生成的报告；不要用测试样例代替真实探测结果。

磁盘分区是部署策略，DHCP 不提供的静态地址是服务商约束，两者仍需明确声明。不会自动选择并格式化某个猜测的磁盘，也不会把临时安装环境中的 IP 当作长期网络配置。

## 存储与更新

| 路径 | 存储 | 重启后 |
| --- | --- | --- |
| `/` | tmpfs，上限为内存的 50% | 清空，系统配置重新生成 |
| `/nix` | Btrfs 子卷 | 保留软件、系统代际与 SSH 主机密钥 |
| `/home` | Btrfs 子卷 | 保留用户文件与 Home Manager 数据 |
| `/boot` | 512 MiB ESP | 保留启动文件 |

本次目录重构保留上述布局、管理员 UID、SSH 策略以及 `system.stateVersion` / `home.stateVersion`。旧 ext4 根不能通过重建自动转成此布局；`/var` 的数据库、系统容器和 ACME 状态仍需单独持久化。

```bash
nix develop
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 验证第二个 SSH 会话后持久化
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
```

完整检查包含系统、Home Manager、disko、格式 / 静态检查，以及需要 Linux KVM 的安装重启测试。CI 为尚未填写公钥的模板生成临时公钥，只用于测试工作区。

- [目录设计与迁移](docs/architecture.md)
- [定制与新增机器](docs/customization.md)
- [安装与更新](docs/deployment.md)
- [用户环境与软件源](docs/home-manager.md)
- [可选服务](docs/services.md)
- [检查与运维](docs/operations.md)
