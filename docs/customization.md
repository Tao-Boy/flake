# 主机定制

## 网络

默认使用 systemd-networkd，以 `en* eth*` 匹配常见 VPS 物理网卡，启用 DHCP 与 IPv6 RA。多网卡机器应改成准确名称，防止多个接口同时获取默认路由。

在初始 VPS 上确认：

```bash
ip -br link
ip -br address
ip route
ip -6 route
cat /etc/resolv.conf
```

DHCP 不适用于所有服务商。需要静态地址时，在主机配置中使用服务商提供的真实参数。以下地址仅为文档示例，不能直接部署：

```nix
fleet.network = {
  interface = "ens3";
  dhcp = false;
  acceptRA = false;
  addresses = [
    "192.0.2.10/24"
    "2001:db8:1234::10/64"
  ];
  gateway4 = "192.0.2.1";
  gateway6 = "fe80::1";
  dns = [ "1.1.1.1" "9.9.9.9" ];
};
```

默认路由设置 `GatewayOnLink = true`，便于处理服务商提供的子网外网关；仍要核对 /32 IPv4、IPv6 前缀、链路本地网关及路由要求。需要多个接口、策略路由或 VLAN 时，直接在该 host 中扩展 `systemd.network`。

## 磁盘与固件

```nix
fleet.diskDevice = "/dev/disk/by-id/<实际磁盘标识>";
fleet.bootMode = "hybrid";
```

| 模式 | 分区 | GRUB |
| --- | --- | --- |
| `hybrid` | BIOS boot + ESP + ext4 root | 安装 BIOS 和 EFI，引导不依赖写入 NVRAM |
| `bios` | BIOS boot + ext4 root | BIOS |
| `uefi` | ESP + ext4 root | EFI 可移动路径 |

默认 ext4 减少 VPS 上的复杂度。默认没有磁盘加密和持久化拆分，也不设置磁盘 swap；zram 提供内存压缩 swap。需要 LUKS、Btrfs 或 RAID 时，修改独立的 storage 模块并单独验证启动与恢复流程。

已安装主机上，修改 disko 不等于在线迁移现有分区。日常 `rebuild` 不会重新运行分区脚本；不要为了“应用磁盘配置”重跑首次安装入口。

## 多主机

复制 `hosts/vps/` 到 `hosts/edge/`，调整磁盘、公钥、网络和服务；在 `hosts/default.nix` 中登记：

```nix
{
  vps = ./vps;
  edge = ./edge;
}
```

flake 会自动生成 `nixosConfigurations.edge`，同时检查全部主机。默认主机名与清单中的名称一致；需要时可在 host 中指定 `networking.hostName`。

```bash
git add hosts
nix flake check --no-build
nix run .#preflight -- edge
```

所有主机仅使用 `x86_64-linux`。

## 覆盖默认值

模块中可调整的系统默认值使用 `lib.mkDefault`。主机可直接覆盖：

```nix
nix.settings.max-jobs = 2;
zramSwap.memoryPercent = 25;
time.timeZone = "Asia/Shanghai";
services.qemuGuest.enable = false; # 服务商不提供 guest-agent 通道时可关闭
```

不要无理由使用 `lib.mkForce`。发生冲突时先找出配置来源，明确是主机差异还是共用模块应修改。

`system.stateVersion` 记录初次安装时的状态兼容版本，升级输入时不要自动递增。增加到已有 NixOS 主机时，应保留它原先的 stateVersion。

## 用户软件与 dotfiles

用户软件安装和 Bash/Git/Neovim/tmux 配置放在 `home/`，不要再添加到 `environment.systemPackages`。稳定源使用 `pkgs`，精选新版本使用 `pkgsUnstable`；详见 [Home Manager 与双软件源](home-manager.md)。

`fleet.access.adminUser` 决定 Home Manager 管理的账户，用户名与 home 目录自动继承 NixOS 账户，不硬编码为 `ops`。可以在主机配置中用 `home-manager.users.<用户名>` 覆盖或补充主机专用用户设置。

## SSH 端口

```nix
fleet.access.sshPort = 2222;
```

模块会同步更新 NixOS 防火墙与 fail2ban。修改服务商侧防火墙后，日常更新仍用旧端口连接：

```bash
nix run .#rebuild -- vps ops@SERVER_IP --port 22 --action test
ssh -p 2222 ops@SERVER_IP
nix run .#rebuild -- vps ops@SERVER_IP --port 2222 --action switch
```

单纯换端口不能替代公钥登录与权限控制。更换公钥时保留旧公钥，验证新连接后再移除旧公钥。
