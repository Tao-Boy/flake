# 定制与新增机器

## 用户与机器差异

系统只有一个用户，定义在 `user.nix`：用户名 `tau`、UID 1000、SSH 公钥，属于 `wheel` 组以便使用 sudo。完整公钥取自 `.pub` 文件；私钥、密码和令牌不进入仓库。修改用户名时，全局搜索 `tau` 一并替换：`user.nix`、机器中的 `home-manager.users.tau`，以及 `modules/sops.nix` 中的 `/home/tau/.config` 路径；已有家目录和密钥不会自动迁移。

机器的个别设置直接写在 `machines/vps/default.nix`，例如：

```nix
# machines/vps/default.nix
services.openssh.ports = [ 2222 ];
time.timeZone = "Asia/Shanghai";
zramSwap.memoryPercent = 25;
```

模块中已经设置过的值（例如 `nix.settings.max-jobs`）不能在机器中再写一遍，直接修改模块文件即可。

系统模块在 `modules/`，用户软件在 `home/`。系统功能在机器 `default.nix` 的 imports 中逐行选择，用户软件在 `home.nix` 中选择。包使用 `pkgs.xxx` 或 `pkgsUnstable.xxx`。

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

分区布局在 `modules/ephemeral-root.nix`：GPT、BIOS boot、ESP、ext4 `/nix` 和 `/home`，加 tmpfs 根。它同时把日志设为只保存在内存中，并同时支持 BIOS / UEFI 启动。SSH 主机密钥加密保存在仓库，解密用的 age 私钥由用户自己保存，服务器上的副本在持久的 `/home/tau/.config/sops/age/keys.txt`。

`/home` 为 4 GiB，`/nix` 使用剩余磁盘空间；两者是独立 ext4 分区，不共享空闲容量。在机器的 `storage.nix` 中调整家目录分区大小：

```nix
disko.devices.disk.system.content.partitions.home.size = "8G";
```

该值是安装时的分区策略，应结合磁盘容量和已有数据量确定；改值并重建不会自动调整已有分区。

若需要持久根、加密或多盘，创建另一存储模块，在机器中选择它。通过 nixos-anywhere 生成的硬件文件不声明挂载点；手工生成时使用 `--no-filesystems`，以免与 disko 文件系统定义重复。

## 新增机器

复制 `machines/vps/` 为 `machines/edge/`，分别在 `default.nix` 和 `home.nix` 中调整所需系统与用户模块的 imports，并把 `networking.hostName` 改为 `"edge"`。为新机器准备独立硬件文件，调整存储和系统差异；不要沿用其他实际机器生成的硬件配置。在 `flake.nix` 中复制 vps 的入口：

```nix
nixosConfigurations.edge = inputs.nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  modules = [ ./machines/edge ];
};
```

平台在机器的 `default.nix` 中通过 `nixpkgs.hostPlatform` 声明，Home Manager 用户入口通过 `home-manager.users.tau = ./home.nix;` 指定。不需要 Home Manager 的机器删掉该行与 `modules/home-manager.nix` 导入；不需要代理的机器删掉 `modules/proxy.nix` 导入。`modules/ssh.nix` 默认所有机器共用 `secrets/ssh_host_ed25519_key`；新机器想用自己的主机密钥时，按[安装说明](deployment.md#ssh-主机密钥)另外加密一份，并在机器入口写 `sops.secrets.ssh_host_ed25519_key.sopsFile = lib.mkForce ../../secrets/edge_ssh_host_ed25519_key;`（文件开头需改为 `{ lib, ... }:`）。CI 只构建 vps；需要时在 `flake.nix` 的 `checks` 中仿照 vps 增加一项。

当前开发环境与 VPS 启动布局使用 x86_64 Linux；添加其他架构需适配工具平台和启动布局。以下远程安装需先按[安装说明](deployment.md)准备 age 私钥副本；选择启用 Xray 的机器需要部署该文件：

```bash
git add machines home
nix flake check --no-build --no-write-lock-file
nix run .#install -- --flake .#edge --target-host root@YOUR_SERVER \
  --extra-files "$PWD/work/extra-files" --chown /home/tau 1000:100 --build-on local \
  --generate-hardware-config nixos-generate-config ./machines/edge/hardware-configuration.nix
```

上面的安装会清空配置指定的磁盘。不启用 Xray 且无需额外文件的机器可省略 `--extra-files`。已安装机器使用 `nixos-rebuild test` / `switch` 更新。
