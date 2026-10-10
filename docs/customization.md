# 定制与新增机器

## 身份与机器差异

管理员用户名、公钥统一在 `users.nix`。完整公钥取自 `.pub` 文件；私钥、密码和令牌不进入仓库。系统账号、Nix 信任用户、SSH AllowUsers 与 Home Manager 使用同一身份。UID 为 1000；修改用户名不会自动迁移家目录或修改旧文件归属。

机器覆盖共享默认值时直接使用 NixOS 选项：

```nix
# machines/vps/default.nix
services.openssh.ports = [ 2222 ];
time.timeZone = "Asia/Shanghai";
zramSwap.memoryPercent = 25;
nix.settings.max-jobs = 2;
```

共享系统配置在 `modules/nixos/`，全部用户软件配置在 `home/`。机器的系统差异和软件选择均放在 `machines/<name>/`，用户模块由其中的 `home.nix` 选择。包使用 `pkgs.xxx` 或 `pkgsUnstable.xxx`。

## 硬件配置与网络

`machines/vps/hardware-configuration.nix` 按固定路径导入，不执行硬件探测或读取报告。仓库提供 QEMU 模板，用户可保留适用模板，或显式使用以下安装参数生成并替换：

```bash
--generate-hardware-config nixos-generate-config ./machines/vps/hardware-configuration.nix
```

生成流程由用户启动，后续重建使用保存的 Nix 文件。迁移已安装机器也可保留原有硬件配置，或用 `nixos-generate-config --show-hardware-config --no-filesystems` 生成，具体见[安装说明](deployment.md)。

常见 VPS 的网络只需要 DHCP / IPv6 RA。NixOS 根据接口类型生成 networkd 规则，使用服务商返回的地址、路由和 DNS，不依赖 `eth0` / `ens3` 等名称。DHCP 身份使用 MAC / link-layer，避免 tmpfs 根导致 machine-id 变化影响租约。

DHCP 是自动协商，不会识别服务商未广播的静态配置。服务商要求静态网络时，先核对 `ip -br address`、`ip route`、`ip -6 route` 和服务商说明，然后在机器入口加入：

```nix
networking.useDHCP = false;
networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
systemd.network.networks."10-uplink" = {
  matchConfig.Name = "ens3";
  networkConfig = {
    DHCP = "no";
    IPv6AcceptRA = false;
  };
  address = [ "203.0.113.10/24" ];
  routes = [ { Gateway = "203.0.113.1"; GatewayOnLink = true; } ];
  linkConfig.RequiredForOnline = "routable";
};
```

示例地址是文档保留地址，必须替换。关闭 `useDHCP` 后默认 DHCP 规则不再生成。静态 IPv6、额外网卡、MTU 和多路径路由按实际情况使用原生选项。

## 存储

`machines/vps/storage.nix` 选择布局并声明目标整盘，disko 与 GRUB 共用该设备。优先选择稳定的 `/dev/disk/by-id/...`，用 `lsblk` 核对目标。硬件配置生成不会选择磁盘擦除目标。

共享布局在 `modules/nixos/storage/ephemeral-root.nix`：GPT、BIOS boot、ESP、Btrfs `/nix` 和 `/home`，加 tmpfs 根。它同时管理易失日志和持久 SSH 主机密钥；机器选择该布局后才应用这些策略。BIOS / UEFI 兼容设置和原布局保持一致。

若需要持久根、加密或多盘，创建另一存储模块，在机器中选择它。通过 nixos-anywhere 生成的硬件文件不声明挂载点；手工生成时使用 `--no-filesystems`，以免与 disko 文件系统定义重复。

## 新增机器

复制 `machines/vps/` 为 `machines/edge/`，在 `home.nix` 中调整软件模块的 imports。为新机器准备独立硬件文件，调整存储和系统差异；不要沿用其他实际机器生成的硬件配置。在 `machines/default.nix` 增加：

```nix
edge = {
  system = "x86_64-linux";
  module = ./edge;
  home = ./edge/home.nix;
};
```

机器清单自动生成 `nixosConfigurations.edge`，CI 直接构建清单中的系统和 disko 脚本。当前开发环境与 VPS 启动布局使用 x86_64 Linux；添加其他架构需适配工具平台和启动布局。

```bash
git add machines home
nix flake check --no-build --no-write-lock-file
nix run .#install -- --flake .#edge --target-host root@YOUR_SERVER \
  --generate-hardware-config nixos-generate-config ./machines/edge/hardware-configuration.nix
```

上面的安装会清空配置指定的磁盘。已安装机器使用 `nixos-rebuild test` / `switch` 更新。
