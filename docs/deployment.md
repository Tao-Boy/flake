# 首次部署与 nixos-anywhere

## 准备条件

- 本机：x86_64 Linux、Nix、Git；启用 `nix-command flakes`，克隆仓库后在根目录运行命令。
- 目标：x86_64 KVM/QEMU 虚拟机、可执行 kexec 的内核、root SSH、能访问 GitHub 与 Nix 二进制缓存。
- 建议目标至少 2 GiB 内存；小机器可从 NixOS 救援镜像安装，或选择本地构建。zram 是安装后的配置，不能解决 kexec 安装器的初始内存不足。
- 在服务商防火墙中允许初始 SSH、kexec 安装器的 22 端口和安装后的 SSH 端口。
- 准备数据备份与服务商救援环境。OpenVZ/LXC、Secure Boot、特殊磁盘控制器或不支持 kexec 的服务商需要专门适配。

首次安装会销毁 `fleet.diskDevice` 上全部原有分区和文件系统。默认混合布局并不能确认哪块磁盘是正确的目标，仍须在远端检查 `lsblk`。

## 部署入口

```bash
nix run .#install -- vps root@<VPS地址> \
  --port 22 \
  --identity ~/.ssh/id_ed25519 \
  --build-on local \
  --dry-run
```

去掉 `--dry-run` 才会调用安装器。私钥始终位于本机，不复制到仓库或目标系统。

| 参数 | 含义 |
| --- | --- |
| `vps` | `hosts/default.nix` 中登记的 flake 主机名称 |
| `root@<VPS地址>` | 初始系统的 root SSH 目标，也可使用 SSH config 别名 |
| `--port` | 初始系统当前的 SSH 端口；默认 22 |
| `--identity` | 本机用于访问初始系统的私钥文件 |
| `--build-on auto\|local\|remote` | nixos-anywhere 构建位置；默认 auto |
| `--dry-run` | 仅评估本机配置和检查远端，完全不运行安装器 |

脚本会先验证最终配置中的每个 SSH 公钥，再评估 NixOS 的 toplevel 与 diskoScript，检查目标架构/root 权限/块设备/固件，显示磁盘和网络，最后要求在交互终端输入：

```text
ERASE root@<VPS地址> /dev/vda
```

它不会确认公钥对应的私钥是否由你持有，也无法推断服务商的正确静态路由；部署前必须自行核对。

## 安装器端口与主机密钥

初始系统 SSH 使用 `--port`，kexec 后的临时安装器使用 **22**，安装后的系统使用 `fleet.access.sshPort`。三者可以不同，服务商侧都应提前放行。

脚本首次只读检查使用已验证的 known_hosts，并启用 BatchMode；先手动建立 SSH 连接。nixos-anywhere 在 kexec 阶段自行管理临时密钥和主机密钥检查。安装后的 SSH 服务禁用 root 登录。

默认不复制初始系统的 SSH host private keys。出现主机密钥变更时，先通过控制台核对指纹，再更新 known_hosts。必要时可自行使用安装器的 `--copy-host-keys` 功能，明确评估是否信任初始系统中的密钥。

## 直接使用固定版本的安装器

仓库通过 `packages.x86_64-linux.nixos-anywhere = pkgs.nixos-anywhere` 提供部署工具；其源码版本及下载哈希随 nixpkgs 一同固定，避免用一次性 `github:.../main` 部署命令引入漂移。

只有在完成同等预检、填写公钥且确认目标磁盘后，才直接运行：

```bash
nix run .#nixos-anywhere -- \
  --flake .#vps \
  --target-host root@<VPS地址> \
  --build-on local
```

该命令会实际安装和擦盘；它不带本仓库部署脚本的 ERASE 确认。

可先在支持 KVM 的本机测试磁盘和安装过程，无需连接真实 VPS：

```bash
nix run .#nixos-anywhere -- --flake .#vps --vm-test
```

VM 测试需要 /dev/kvm 和足够内存，也不能验证服务商网络、固件和硬件。本仓库 CI 评估并构建系统及分区脚本，不进行真实服务器部署。

## 硬件配置

`hosts/vps/hardware-configuration.nix` 提供通用 KVM/virtio/NVMe 默认值；特殊硬件需要调整。

nixos-anywhere 支持：

```text
--generate-hardware-config nixos-generate-config <本机输出路径>
```

这会在安装过程中生成配置并写入本地文件，不是单独的只读扫描。使用该参数前明确规划导入位置并预留备份。生成文件中的 `fileSystems`、`swapDevices` 和可能冲突的启动配置，应与 disko 的唯一磁盘定义协调，不要在部署脚本外未经核对直接覆盖文件。本仓库的通用 KVM 模板无需此参数即可构建。

## 安装失败

- kexec 失败：检查虚拟化类型、内核限制、Secure Boot；使用服务商的 NixOS 救援镜像更可靠。
- 安装器无法连接：检查 22 端口、网络接口是否保留 DHCP、IPv6-only 环境与服务商防火墙。
- 缓存下载失败：检查 DNS、网络访问和目标内存。
- 安装后无法引导：通过控制台确认 BIOS/UEFI，检查磁盘选择与 GRUB 安装目标。
- 安装后无法登录：通过救援环境修复公钥、网卡和防火墙。用户及 root 默认都没有可用密码。
