# 定制与新增机器

## 用户与机器差异

系统只有一个用户，定义在 `modules/nixos/base/users.nix`：用户名 `tau`、UID 1000、SSH 公钥，属于 `wheel` 组以便使用 sudo。所有主机共用该模块中的用户公钥，以及 `secrets/id_ed25519` 中由 SOPS 加密的配套私钥；更换时按[安装说明](deployment.md#准备)同时更新两者。明文私钥、密码和令牌不进入仓库。修改用户名时，全局搜索 `tau` 一并替换用户模块、`home-manager.users.tau` 和用户目录路径；已有家目录不会自动迁移。

机器的个别设置直接写在相应的 `hosts/<name>/default.nix`，例如：

```nix
# hosts/vps-pi/default.nix
services.openssh.ports = [ 2222 ];
time.timeZone = "Asia/Shanghai";
zramSwap.memoryPercent = 25;
```

系统模块在 `modules/nixos/`，用户软件在 `home/`。主机入口先导入 `modules/nixos/server/default.nix` 中的共用底座，再逐项选择额外系统功能；用户软件在 `home.nix` 中选择。包使用 `pkgs.xxx` 或 `pkgsUnstable.xxx`。默认 UTC 时区可在主机入口直接覆盖，`system.stateVersion` 仍由每台主机单独保留。

## 硬件配置与网络

`hosts/vps-pi/hardware-configuration.nix` 和 `hosts/vps-dev/hardware-configuration.nix` 各自按固定路径导入，不执行硬件探测或读取报告。每台服务器使用独立硬件文件；仓库提供 QEMU 模板，用户可保留适用模板，或显式使用以下安装参数生成并替换（以 `vps-pi` 为例）：

```bash
--generate-hardware-config nixos-generate-config ./hosts/vps-pi/hardware-configuration.nix
```

安装 `vps-dev` 时，生成路径改为 `./hosts/vps-dev/hardware-configuration.nix`。

常见 VPS 的网络只需要 DHCP / IPv6 RA。NixOS 根据接口类型生成 networkd 规则，使用服务商返回的地址、路由和 DNS，不依赖 `eth0` / `ens3` 等名称。服务商要求静态网络时，在主机入口加入相应原生选项。

## 存储

`hosts/<name>/disko-fs.nix` 导入 `modules/nixos/base/disko.nix` 的共用布局，并声明目标整盘和启动差异。`vps-pi` 使用 `/dev/vda`（当前本机 `lsblk` 确认为 60 GiB），`vps-dev` 使用独立磁盘文件指定 `/dev/sda`；Oracle ARM 默认 `/dev/sda`。disko 与 GRUB 共用该设备；Oracle ARM 通过 UEFI 启动，不向 BIOS 设备安装 GRUB。优先选择稳定的 `/dev/disk/by-id/...`，用 `lsblk` 核对目标。硬件配置生成不会选择磁盘擦除目标。

仓库定义的共用布局是 GPT、512 MiB EFI `/boot`，以及占满剩余空间的 ext4 `/`；两台 x86_64 VPS 另有 1 MiB BIOS boot 分区。按此布局安装后，根目录直接位于硬盘；`/nix`、`/home`、`/var` 和日志都在根文件系统中持久保存，不使用根 tmpfs、`/nix/persist` 或 impermanence。

当前本机根 `/` 仍为 tmpfs，旧布局仍有 `/nix/persist`，不能据此认为新版布局已经部署。旧布局到新 ext4 布局需按[迁移说明](deployment.md#旧布局迁移到-ext4-根分区)备份重装，不能通过普通重建转换；安装命令会格式化 `disko-fs.nix` 指定的整盘。单独将主机配置改名为 `vps-pi` 无需擦盘，hostname 要在重建并激活后才生效。

## 新增机器

复制 `hosts/vps-pi/` 为 `hosts/edge/`，分别在 `default.nix` 和 `home.nix` 中调整所需系统与用户模块的 imports；仅需开发环境时可从 `hosts/vps-dev/` 开始，避免带入 pi-web 等应用服务。为新机器准备独立硬件文件和磁盘文件，不要沿用其他实际机器的硬件配置。在 `outputs/default.nix` 的 `hosts` 表中增加一行：

```nix
hosts = {
  vps-pi = "x86_64-linux";
  vps-dev = "x86_64-linux";
  oracle-arm = "aarch64-linux";
  edge = "x86_64-linux";
};
```

表中的名字与 `hosts/<name>/` 目录同名，自动用作 `networking.hostName`。系统入口、架构和对应 `checks` 均由此生成。

不需要 Home Manager 的机器删掉 `modules/nixos/base/home-manager.nix` 导入和 `home-manager.users.tau`；不需要 Xray 客户端的机器删掉 `modules/nixos/server/xray-client.nix`，不需要 Xray 服务端的机器删掉 `modules/nixos/server/xray-server.nix`。新机器按[安装说明](deployment.md#准备)生成自己的 SSH 主机密钥，并准备自己的磁盘布局。用户登录密钥和 age admin key 可共用，但不同服务器不能复制使用同一 SSH 主机私钥。

当前声明 `vps-pi`、`vps-dev` 两台 x86_64 主机和 aarch64 的 `oracle-arm`；开发工具按 `hosts` 表中使用的架构自动提供，添加其他架构时需确认软件包可用性和启动布局。以下远程安装需先按[安装说明](deployment.md#准备)以 `install_host=edge` 准备 `work/edge/extra-files` 中的密钥：

```bash
git add hosts modules home outputs
nix flake check --no-build --no-write-lock-file
nix run .#install -- --flake .#edge --target-host root@YOUR_SERVER \
  --extra-files "$PWD/work/edge/extra-files" --chown /home/tau 1000:100 \
  --build-on local \
  --generate-hardware-config nixos-generate-config ./hosts/edge/hardware-configuration.nix
```

上面的安装会清空配置指定的磁盘。已采用仓库 ext4 根布局的机器使用 `nixos-rebuild test` / `switch` 更新。
