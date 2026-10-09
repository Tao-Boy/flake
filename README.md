# flake

面向 **x86_64-linux VPS** 的 NixOS 配置。系统使用 NixOS 26.05；用户软件由 Home Manager 管理；Git、Neovim、fzf、bat、eza、ripgrep、fd、btop 使用独立锁定的 nixpkgs-unstable。

目录分工参考 [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)。配置逐项声明，包名写明 `pkgs.xxx` 或 `pkgsUnstable.xxx`，关键位置有中文注释。

## 目录

```text
flake.nix                   # 软件源和 outputs 入口
flake.lock                  # 固定输入版本
outputs/default.nix         # 主机、安装包、开发环境、两个构建检查
lib/nixos-system.nix        # 接入 disko / Home Manager
vars/default.nix            # 管理员用户名和 SSH 公钥
hosts/vps/
  default.nix               # 网络、时区、模块选择
  disk-config.nix           # tmpfs 根、持久 /nix 和 /home、GRUB
  hardware-configuration.nix
modules/
  base/                     # Nix、用户、额外系统工具
  nixos/
    server.nix              # VPS 共用服务
    nginx.nix               # 可选 Nginx
    containers.nix          # 可选 Podman
home/
  base/
    default.nix
    shell.nix               # Bash、fzf、bat、eza
    tools.nix               # 用户软件、Git、Neovim、tmux
  hosts/vps.nix             # 当前主机的用户设置
scripts/vps.sh              # 直接调用 nixos-anywhere
docs/                      # 配置、安装、软件管理和运维说明
```

配置链路：`flake.nix → outputs/default.nix → lib/nixos-system.nix → hosts/vps/default.nix + home/hosts/vps.nix`。

## 配置

```bash
git clone https://github.com/Tao-Boy/flake.git
cd flake
```

先改三个位置：

1. `vars/default.nix`：填入完整 SSH 公钥，按需修改管理员 `tau`。
2. `hosts/vps/disk-config.nix`：核对整块磁盘，默认 `/dev/vda`。
3. `hosts/vps/default.nix`：核对网卡和地址，默认 DHCP + IPv6 RA。

```nix
# vars/default.nix
{
  username = "tau";
  sshKeys = [
    "ssh-ed25519 AAAA...你的完整公钥... you@laptop"
  ];
}
```

新建的配置文件先 `git add`。填完公钥后可检查配置：

```bash
nix flake check --no-build
```

## 文件系统

| 路径 | 存储 | 重启后 |
| --- | --- | --- |
| `/` | tmpfs，容量上限为内存的 50% | 清空，声明式配置重新生成 |
| `/nix` | Btrfs 子卷 | 保留软件包、系统代际和 SSH 主机密钥 |
| `/home` | Btrfs 子卷 | 保留用户文件、dotfiles 和用户软件数据 |
| `/boot` | 512 MiB ESP | 保留引导器和启动文件 |

`/nix` 和 `/home` 共享剩余磁盘空间。`/etc`、`/var`、`/root` 等目录位于临时根上；`/dev`、`/proc`、`/sys`、`/run` 使用 Linux 的常规虚拟文件系统。手工修改系统文件和服务运行数据会在重启后消失，需要保留的数据应放在持久目录中。

**旧版 ext4 根分区不能通过 `nixos-rebuild` 自动转换为此布局。迁移前备份数据，再重装或单独规划磁盘迁移。**

## 安装

**安装会按照 disko 配置清空目标磁盘。** 目标需要 root SSH 访问；先确认备份、磁盘和网络配置。

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER
```

`scripts/vps.sh` 只执行 `nixos-anywhere "$@"`，参数全部原样传给上游。指定私钥或当前 SSH 端口时使用上游参数：

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER \
  -i ~/.ssh/id_ed25519 --ssh-port 22
```

也可以直接运行 `nix run .#nixos-anywhere -- …`。默认磁盘布局同时支持 BIOS / UEFI；安装后通过管理员公钥登录，root SSH 和密码登录关闭。

## 更新

在仓库根目录进入开发环境，直接使用标准 `nixos-rebuild`：

```bash
nix develop
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 用另一个 SSH 会话验证后持久化
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
```

Home Manager 随系统一起激活。额外系统工具写在 `modules/base/packages.nix`，用户软件写在 `home/base/tools.nix`，主机差异写在 `home/hosts/vps.nix`。

## 文档

- [常用语法、配置与新增主机](docs/customization.md)
- [nixos-anywhere 安装与远程更新](docs/deployment.md)
- [Home Manager 与双软件源](docs/home-manager.md)
- [可选 Nginx / Podman](docs/services.md)
- [检查、回滚和运维](docs/operations.md)

`checks` 只包含安装包与 Home Manager 环境。CI 构建这两个目标和 VPS 系统、disko 脚本，并在虚拟机中验证启动、重启后持久目录与 SSH 指纹保留、临时目录清空；空公钥模板只在 CI 工作区注入临时测试公钥。
