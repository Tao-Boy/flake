# 定制与新增机器

## 用户与机器差异

系统只有一个用户，定义在 `modules/nixos/base/users.nix`：用户名 `tau`、UID 1000、SSH 公钥，属于 `wheel` 组以便使用 sudo。所有主机共用该模块中的用户公钥，以及 `secrets/id_ed25519` 中由 SOPS 加密的配套私钥；更换时按[安装说明](deployment.md#准备)同时更新两者。明文私钥、密码和令牌不进入仓库。修改用户名时，全局搜索 `tau` 一并替换用户模块、`home-manager.users.tau` 和用户目录路径；已有家目录不会自动迁移。

机器的个别设置直接写在 `hosts/vps/default.nix`，例如：

```nix
# hosts/vps/default.nix
services.openssh.ports = [ 2222 ];
time.timeZone = "Asia/Shanghai";
zramSwap.memoryPercent = 25;
```

系统模块在 `modules/nixos/`，用户软件在 `home/`。主机入口先导入 `modules/nixos/server/default.nix` 中的共用底座，再逐项选择额外系统功能；用户软件在 `home.nix` 中选择。包使用 `pkgs.xxx` 或 `pkgsUnstable.xxx`。默认 UTC 时区可在主机入口直接覆盖，`system.stateVersion` 仍由每台主机单独保留。

## 硬件配置与网络

`hosts/vps/hardware-configuration.nix` 按固定路径导入，不执行硬件探测或读取报告。仓库提供 QEMU 模板，用户可保留适用模板，或显式使用以下安装参数生成并替换：

```bash
--generate-hardware-config nixos-generate-config ./hosts/vps/hardware-configuration.nix
```

常见 VPS 的网络只需要 DHCP / IPv6 RA。NixOS 根据接口类型生成 networkd 规则，使用服务商返回的地址、路由和 DNS，不依赖 `eth0` / `ens3` 等名称。服务商要求静态网络时，在主机入口加入相应原生选项。

## 存储

`hosts/<name>/disko-fs.nix` 导入 `modules/nixos/base/disko.nix` 的共用布局，并声明目标整盘和启动差异。disko 与 GRUB 共用该设备；Oracle ARM 通过 UEFI 启动，不向 BIOS 设备安装 GRUB。优先选择稳定的 `/dev/disk/by-id/...`，用 `lsblk` 核对目标。硬件配置生成不会选择磁盘擦除目标。

共用布局是 GPT、512 MiB EFI `/boot`，以及占满剩余空间的 ext4 `/`；VPS 另有 1 MiB BIOS boot 分区。根目录直接位于硬盘；`/nix`、`/home`、`/var` 和日志都在根文件系统中持久保存，不使用根 tmpfs、`/nix/persist` 或 impermanence。

修改磁盘布局不能通过普通重建转换。变更分区时需要备份数据，在确认目标设备后重新安装；安装命令会格式化 `disko-fs.nix` 指定的整盘。

## 新增机器

复制 `hosts/vps/` 为 `hosts/edge/`，分别在 `default.nix` 和 `home.nix` 中调整所需系统与用户模块的 imports。为新机器准备独立硬件文件和磁盘文件，不要沿用其他实际机器的硬件配置。在 `outputs/default.nix` 的 `hosts` 表中增加一行：

```nix
hosts = {
  vps = "x86_64-linux";
  oracle-arm = "aarch64-linux";
  edge = "x86_64-linux";
};
```

表中的名字与 `hosts/<name>/` 目录同名，自动用作 `networking.hostName`。系统入口、架构和对应 `checks` 均由此生成。

不需要 Home Manager 的机器删掉 `modules/nixos/base/home-manager.nix` 导入和 `home-manager.users.tau`；不需要 Xray 客户端的机器删掉 `modules/nixos/server/xray-client.nix`，不需要 Xray 服务端的机器删掉 `modules/nixos/server/xray-server.nix`。新机器按[安装说明](deployment.md#准备)生成自己的主机密钥，并准备自己的磁盘布局。

当前声明 x86_64 VPS 和 aarch64 Oracle ARM 主机；开发工具按 `hosts` 表中使用的架构自动提供，添加其他架构时需确认软件包可用性和启动布局。以下远程安装需先按[安装说明](deployment.md#准备)准备密钥：

```bash
git add hosts modules home outputs
nix flake check --no-build --no-write-lock-file
nix run .#install -- --flake .#edge --target-host root@YOUR_SERVER \
  --extra-files "$PWD/work/extra-files" --chown /home/tau 1000:100 \
  --build-on local \
  --generate-hardware-config nixos-generate-config ./hosts/edge/hardware-configuration.nix
```

上面的安装会清空配置指定的磁盘。已安装机器使用 `nixos-rebuild test` / `switch` 更新。
