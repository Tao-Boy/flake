# flake

用于 **x86_64 KVM/QEMU VPS** 的模块化 NixOS flake。以 NixOS **26.05** 为基础，使用 **disko** 声明磁盘布局，使用 **nixos-anywhere** 首次安装，以 **nixos-rebuild** 进行后续更新。

> 这是需要填写主机参数的模板。默认 SSH 公钥列表为空，部署脚本会拒绝安装。首次安装会清空指定磁盘，请先备份，并准备服务商的救援环境/控制台。

## 配置结构

```text
.
├── flake.nix                    # 输入、主机生成、部署工具、开发环境和检查
├── flake.lock                   # 固定 nixpkgs 与 disko；部署工具来自同一 nixpkgs
├── hosts/
│   ├── default.nix              # 主机清单；新增主机只需登记一次
│   └── vps/
│       ├── default.nix          # 磁盘、启动方式、公钥、网络、主机服务
│       └── hardware-configuration.nix
├── profiles/vps.nix             # VPS 场景组合与内核参数
├── modules/
│   ├── options.nix             # fleet.* 接口、类型及校验
│   ├── access.nix              # 管理用户、SSH、sudo、fail2ban
│   ├── networking.nix          # networkd、resolved、nftables 防火墙
│   ├── storage.nix             # disko 分区与 GRUB，唯一的文件系统来源
│   ├── system/                 # 基础系统、Nix、CLI、日常维护
│   └── services/               # 按需启用 Nginx 与 Podman
├── scripts/vps.sh              # 预检、首次安装、日常更新共用入口
├── docs/                       # 部署、定制、服务与运维说明
└── .github/workflows/ci.yml     # 评估、脚本检查、工具与系统构建
```

共用行为放在模块，VPS 的默认选择放在 profile，具体服务器参数放在 host。模块通过 NixOS options 传值，避免到处传递特殊参数、硬编码主机信息或覆盖 `pkgs`。

## 默认包含

| 范围 | 内容 |
| --- | --- |
| 系统 | x86_64、KVM guest agent、UTC、chrony、串口控制台 |
| 磁盘 | GPT、ext4；默认 GRUB 同时支持 BIOS 与 UEFI，512 MiB ESP |
| 登录 | `ops` 用户、公钥登录、关闭 root/密码登录、管理员免密码 sudo |
| 网络 | systemd-networkd、DHCP、IPv6 RA、resolved、nftables；默认只放行 SSH |
| 防护与维护 | fail2ban、zram、fstrim、日志容量限制、每周清理 14 天前的 generations |
| CLI | neovim、git、curl、wget、jq/yq、ripgrep、fd、fzf、bat、eza、tmux、htop/btop、ncdu、rsync、mtr、tcpdump、strace 等 |
| 服务 | 可选 Nginx HTTPS 反向代理、Podman；默认关闭 |
| 部署 | 固定版本的 nixos-anywhere、SSH 公钥校验、只读远端预检、擦盘确认、默认 `test` 更新 |

## 快速开始

本机需要 **x86_64 Linux + Nix**，并已启用 `nix-command flakes`。目标 VPS 需要 root SSH 访问、支持 kexec 的完整虚拟机；不适用于 OpenVZ/LXC。

```bash
git clone https://github.com/Tao-Boy/flake.git
cd flake
nix develop
```

编辑 `hosts/vps/default.nix`：

1. 用 `lsblk` 确认 `fleet.diskDevice`，默认是 `/dev/vda`，也可使用完整的 `/dev/disk/by-id/...`。
2. 在 `fleet.access.sshPublicKeys` 填入完整的 SSH **公钥**。
3. 核对启动方式、网卡名称、DHCP/静态地址以及服务商的路由要求。
4. 对照实际硬件检查 `hardware-configuration.nix`。

```nix
fleet.access.sshPublicKeys = [
  # 在引号中粘贴自己的完整 .pub 文件内容。
];
```

上面的空列表不是可部署的设置。先添加真实公钥，再执行：

```bash
git add .
nix flake check --no-build
nix run .#preflight -- vps

# 先核对服务商给出的主机指纹，并建立初始 SSH 连接。
ssh root@<VPS地址>

# 只读检查：公钥、配置、目标架构、磁盘与当前网络。
nix run .#install -- vps root@<VPS地址> --dry-run

# 首次安装：需要输入包含目标与磁盘的完整 ERASE 确认文字。
nix run .#install -- vps root@<VPS地址>
```

安装后通过 `ops` 登录。若服务器 SSH 主机密钥发生变化，请通过服务商控制台核对新指纹后再更新本机 known_hosts。

```bash
ssh ops@<VPS地址>

# 后续变更先临时应用；确认第二个 SSH 会话、网络和服务正常后持久化。
nix run .#rebuild -- vps ops@<VPS地址>
nix run .#rebuild -- vps ops@<VPS地址> --action switch
```

## 更多说明

- [首次部署与 nixos-anywhere](docs/deployment.md)：端口、构建位置、硬件扫描、VM 检查与安装限制。
- [主机定制](docs/customization.md)：静态 IPv4/IPv6、BIOS/UEFI、多主机与覆盖默认值。
- [可选服务](docs/services.md)：Nginx/ACME、Podman 与密钥管理。
- [日常运维](docs/operations.md)：升级、回滚、日志、空间与故障恢复。

默认空公钥状态下，NixOS 的防锁定断言会阻止系统构建；部署脚本也会提前拒绝。CI 仅在临时工作区注入一次性测试公钥进行构建，测试密钥不会提交到仓库。使用前必须填写自己的公钥。

MIT License。
