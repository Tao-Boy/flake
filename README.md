# flake

面向 **x86_64-linux VPS** 的 NixOS 配置。系统使用 NixOS 26.05；用户环境交给 Home Manager；Git、Neovim、fzf、bat、eza、ripgrep、fd、btop 使用独立锁定的 nixpkgs-unstable。包含 disko 磁盘配置与 nixos-anywhere 安装入口。

目录分工参考 [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)，按少量 VPS 的需求精简。模块显式导入，主机直接使用原生 NixOS 选项。

## 目录

```text
flake.nix                   # 软件源；outputs 的入口
flake.lock                  # 固定所有输入版本
outputs/default.nix         # 注册主机、部署命令、开发环境、检查
lib/nixos-system.nix        # 接入 disko / Home Manager，传递共用参数
vars/default.nix            # 管理员用户名、SSH 公钥
hosts/vps/
  default.nix               # 主机网络、时区、模块选择
  disk-config.nix           # 目标磁盘、分区、GRUB
  hardware-configuration.nix
modules/
  base/                     # Nix、系统用户、基础系统工具
  nixos/
    server.nix              # VPS 网络基础、SSH、安全、维护
    nginx.nix               # 可选 Web 服务
    containers.nix          # 可选 Podman
home/
  base/
    default.nix
    shell.nix               # Bash、fzf、bat、eza
    tools.nix               # 用户工具、Git、Neovim、tmux
  hosts/vps.nix             # 当前主机的用户配置
scripts/vps.sh              # 安装与更新预检
docs/                      # 配置、部署、软件管理、运维说明
```

配置链路：`flake.nix → outputs/default.nix → lib/nixos-system.nix → hosts/vps + home/hosts/vps.nix`。主机入口决定导入哪些模块；共用值只通过 `myvars` 传入，unstable 包集只传给 Home Manager。

## 首次使用

```bash
git clone https://github.com/Tao-Boy/flake.git
cd flake
```

先改三个位置：

1. `vars/default.nix`：填写完整 SSH 公钥，按需修改默认管理员 `ops`。
2. `hosts/vps/disk-config.nix`：确认整块目标磁盘，默认 `/dev/vda`；默认 GPT + GRUB 同时支持 BIOS/UEFI。
3. `hosts/vps/default.nix`：确认网卡与地址。默认匹配 `en* eth*`、DHCP、IPv6 RA；静态地址按[配置说明](docs/customization.md)修改。

```nix
# vars/default.nix
{
  username = "ops";
  sshKeys = [
    "ssh-ed25519 AAAA...你的完整公钥... you@laptop"
  ];
}
```

将新文件加入 Git 后进行预检：

```bash
git add .
nix run .#preflight -- vps

# 当前目标系统需要 root SSH；先核对并登记服务器的 SSH 主机指纹。
nix run .#install -- vps root@YOUR_SERVER --identity ~/.ssh/id_ed25519 --dry-run
nix run .#install -- vps root@YOUR_SERVER --identity ~/.ssh/id_ed25519
```

**首次安装会清空目标磁盘。** 安装入口先验证公钥、NixOS 配置、目标架构、块设备和固件，再要求在交互终端输入 `ERASE <SSH目标> <磁盘>`。空公钥模板不能部署，也不能通过完整系统构建的登录安全断言。

安装后登录 `ops@YOUR_SERVER`。root 和管理员密码均锁定，SSH 仅允许公钥，管理员拥有免密码 sudo。防火墙、fail2ban、chrony、qemu guest agent、zram、日志限额与定期 GC 默认启用。

## 更新

```bash
# 默认临时 test，验证新的 SSH 会话后再持久化。
nix run .#rebuild -- vps ops@YOUR_SERVER
nix run .#rebuild -- vps ops@YOUR_SERVER --action switch

# 检查与构建；先填公钥。
nix flake check --no-build
nix build .#nixosConfigurations.vps.config.system.build.toplevel
nix develop
nix fmt
```

Home Manager 随 NixOS 一起激活。系统工具放在 `modules/base/packages.nix`，用户软件放在 `home/base/`，主机差异放在 `home/hosts/vps.nix`。无需单独执行 `home-manager switch`。

## 文档

- [配置与新增主机](docs/customization.md)
- [nixos-anywhere 安装与远程更新](docs/deployment.md)
- [Home Manager 与 stable/unstable 软件源](docs/home-manager.md)
- [可选 Nginx / Podman](docs/services.md)
- [检查、回滚、维护与故障排查](docs/operations.md)

GitHub Actions 检查部署脚本、空公钥拦截、所有 flake 输出，并实际构建 Home Manager 环境、VPS 系统与 disko 脚本。空模板在 CI 工作区临时注入生成的测试公钥，不会写回仓库或操作 VPS。
