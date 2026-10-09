# 配置与新增主机

主机直接填写原生 NixOS / disko 选项。常用修改只涉及 `vars/default.nix`、`hosts/vps/` 和 `home/hosts/vps.nix`。

## 常用 Nix 语法

本仓库将软件包和命令逐个写出；日常修改主要用到以下语法：

| 写法 | 含义 |
| --- | --- |
| `{ name = value; }` | 属性集；每项赋值以分号结束 |
| `[ item1 item2 ]` | 列表；元素用空白分隔 |
| `pkgs.sqlite` | 从稳定包集中选取 sqlite |
| `pkgsUnstable.just` | 从 unstable 包集中选取 just |
| `imports = [ ./file.nix ];` | 将模块文件加入配置 |
| `services.openssh.ports = [ 2222 ];` | 设置嵌套配置项 |
| `lib.mkDefault value` | 提供可被主机普通赋值覆盖的默认值 |

路径相对于当前 Nix 文件所在目录。仓库中的导入路径写明 `default.nix`，可以直接打开对应文件。

没有参数需求的模块直接写成属性集。需要软件包等参数时，文件采用下面的形式；NixOS / Home Manager 会自动提供模块参数：

```nix
{ pkgs, pkgsUnstable, ... }:
{
  home.packages = [
    pkgs.sqlite
    pkgsUnstable.just
  ];
}
```

顶部花括号是参数声明，`...` 允许接收系统传入的其他参数；冒号后面的花括号是返回的配置。`home/base/tools.nix` 已采用这个形式，添加软件时直接往列表中加一行即可。

`let name = value; in ...` 用于保存共用值，例如磁盘路径。`users.${myvars.username}` 根据用户名选择账号属性，用户名仍只在 `vars/default.nix` 修改。

`outputs/default.nix` 显式声明主机、安装包和开发环境。安装包只调用 nixos-anywhere；`checks` 只引用已有的安装包和 Home Manager 构建目标。

## 用户与 SSH

在 `vars/default.nix` 修改 `username`、`sshKeys`。公钥应粘贴完整一行 `.pub` 内容；私钥、密码和令牌不能提交。用户名供 NixOS 用户、SSH AllowUsers、sudo、Home Manager 共用。

在 `hosts/vps/default.nix` 加入：

```nix
services.openssh.ports = [ 2222 ];
```

防火墙随 SSH 端口更新。首次安装的 `--ssh-port` 指当前系统的端口；日常重建使用 SSH 客户端配置。修改端口后先 `test`，另开连接验证，再 `switch`。

## 网络

默认 DHCP 适合常见 VPS。先在原系统检查 `ip -br link`、`ip -br address`、`ip route`、`ip -6 route`，并核对服务商的网关/地址要求。多网卡时应将匹配模式改成明确的接口名。

静态地址：替换 `hosts/vps/default.nix` 中整个 `"10-uplink"` 定义，不要同时保留 DHCP：

```nix
systemd.network.networks."10-uplink" = {
  matchConfig.Name = "ens3";
  networkConfig = {
    DHCP = "no";
    IPv6AcceptRA = false;
  };
  address = [
    "203.0.113.10/24"
    # "2001:db8::10/64"
  ];
  routes = [
    { Gateway = "203.0.113.1"; GatewayOnLink = true; }
    # { Gateway = "2001:db8::1"; GatewayOnLink = true; }
  ];
  linkConfig.RequiredForOnline = "routable";
};
networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
```

示例地址是文档保留地址，必须替换。IPv6 使用 RA 时保留 `IPv6AcceptRA = true`；静态 IPv6 则填写真实地址和路由。有特殊 MTU 等要求可直接使用 `linkConfig.MTUBytes`。

## 磁盘和启动

`hosts/vps/disk-config.nix` 的局部变量 `disk` 同时用于 disko 与 GRUB。先用 `lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS` 核对**整块磁盘**，有稳定 by-id 时优先使用。

默认 GPT 分区为 1 MiB BIOS boot、512 MiB ESP、其余 ext4 根分区；BIOS/UEFI 均可启动。保持 `efi.canTouchEfiVariables = false` 与 `efiInstallAsRemovable = true` 可避免依赖 VPS 的可写 EFI 变量。

通常无需改启动模式。若需要：

- 仅 BIOS：将 `grub.efiSupport`、`grub.efiInstallAsRemovable` 改为 `false`，保留 BIOS boot 分区。
- 仅 UEFI：将 `grub.devices` 改为 `[ "nodev" ]`，保留 ESP 和 EFI 设置；可删除 BIOS boot 分区。

当前部署入口支持单块 disko 磁盘与 GRUB；多盘、RAID、其他引导器需调整脚本的预检。disko 是文件系统配置的唯一来源，勿在硬件文件重复声明 `fileSystems`。

`hardware-configuration.nix` 是通用虚拟机驱动起点；特殊硬件按实际探测调整。若复制自动生成的硬件配置，保留所需驱动并去除与 disko 重复的挂载配置。

## 模块和主机差异

在 `hosts/vps/default.nix` 的 `imports` 中选择系统功能；可选 Nginx 和 Podman 见[服务说明](services.md)。共用模块里的 `mkDefault` 可由主机直接覆盖，例如：

```nix
zramSwap.memoryPercent = 25;
nix.settings.max-jobs = 2;
time.timeZone = "Asia/Shanghai";
```

用户软件与 dotfiles 写在 `home/hosts/vps.nix`，全机共用的软件写在 `home/base/`。无需创建新的包装选项。

## 新增 x86_64 主机

1. 复制 `hosts/vps/` 为 `hosts/edge/`，调整磁盘和网络。
2. 复制 `home/hosts/vps.nix` 为 `home/hosts/edge.nix`。
3. 在 `outputs/default.nix` 的 `let` 区域，复制 `vpsSystem` 为 `edgeSystem`，并修改三个主机参数：

```nix
edgeSystem = import ../lib/nixos-system.nix {
  inputs = inputs;
  myvars = myvars;
  name = "edge";
  nixosModule = ../hosts/edge/default.nix;
  homeModule = ../home/hosts/edge.nix;
};
```

在 `in` 后的输出属性集中，保留原来的 vps，并增加 edge：

```nix
nixosConfigurations.vps = vpsSystem;
nixosConfigurations.edge = edgeSystem;
```

主机生成文件现在一次接收全部参数，直接在调用处写明每个值即可。

`git add` 新文件后执行 `nix flake check --no-build`。安装新主机时使用 `nix run .#install -- --flake .#edge --target-host root@YOUR_SERVER`。主机名由 `name` 默认设置，共用管理员/公钥来自 `vars/`。现有 CI 构建 `vps`，新增主机应增加对应系统和用户环境的构建检查。
