# 检查与运维

## 修改后验证

`vps-pi`、`vps-dev` 和 `oracle-arm` 三台主机共用 `modules/nixos/base/users.nix` 中的 SSH 公钥和 `secrets/id_ed25519` 中的加密私钥，更换时同时更新。新增文件执行 `git add`；根目录的明文 `id_ed25519` 已被忽略。开发环境包含 nixfmt、sops、Xray 与安装器。

```bash
nix develop
nix fmt
nix flake check --all-systems --no-build --no-write-lock-file   # 求值全部架构，不构建
nix flake check --no-write-lock-file                          # 构建当前架构的主机系统
```

`checks` 由 `hosts` 表自动生成，按主机架构分组。当前 x86_64 CI 检查格式并构建 `vps-pi`、`vps-dev` 两个配置；Oracle ARM 的构建需在 ARM 主机或配置好 ARM builder 的环境中执行 `nix flake check --system aarch64-linux --no-write-lock-file`。CI 不解密、不连接三台服务器。

## 服务与网络

三台主机检查共用系统服务；`proxy-status` 和 Home Manager 检查适用于 `vps-pi`、`vps-dev`，`podman-pi-web.service` 仅在 `vps-pi` 上检查。`vps-dev` 不启用 pi-web、Podman、Nginx、ACME 或应用 secrets。

```bash
systemctl --failed
journalctl -b -p warning
systemctl status sshd fail2ban chronyd
systemctl status xray sops-install-secrets
proxy-status
networkctl status
resolvectl status
ip -br address
ip route
ss -tulpn
sudo nft list ruleset
sudo fail2ban-client status sshd
systemctl status home-manager-tau.service
sudo systemctl status podman-pi-web.service
```

修改用户名后替换 Home Manager 服务名。DHCP / RA 应提供地址、路由、DNS；服务商只支持静态配置时应主动在机器入口声明。软件防火墙与服务商防火墙须同时允许 SSH 端口。

## 更新与回滚

以下重建适用于已采用仓库 ext4 根布局的主机；当前本机根 `/` 为 tmpfs，必须先按[旧布局迁移说明](deployment.md#旧布局迁移到-ext4-根分区)备份重装。

```bash
nix flake update nixpkgs-unstable
nixos-rebuild test --flake .#vps-pi --target-host tau@YOUR_PI_SERVER --sudo
nixos-rebuild switch --flake .#vps-pi --target-host tau@YOUR_PI_SERVER --sudo
# 远端紧急回滚
sudo nixos-rebuild switch --rollback
```

更新开发机时使用对应的目标：

```bash
nixos-rebuild test --flake .#vps-dev --target-host tau@YOUR_DEV_SERVER --sudo
nixos-rebuild switch --flake .#vps-dev --target-host tau@YOUR_DEV_SERVER --sudo
```

`oracle-arm` 仍使用 `.#oracle-arm` 和 Oracle 实例地址。原 VPS 配置改名为 `vps-pi` 本身无需擦盘，新 hostname 要在目标机重建并激活后才生效。

也可通过服务商控制台从 GRUB 选择旧代际。GC 每周清理 14 天前的旧代际，GRUB 最多展示 10 个配置；已被 GC 删除的代际不能恢复。网络、公钥、端口变更先 `test` 并准备控制台回退路径；旧布局到新 ext4 布局按迁移说明处理。

## 状态与备份

```bash
findmnt /
findmnt /boot
df -h
sudo systemctl status nix-gc.timer fstrim.timer
```

按仓库新布局安装后，根文件系统是硬盘上的 ext4，重启后 `/home/tau`、`/var`、`/etc/ssh` 和 `/nix` 都保留，不需要 impermanence 清单。当前本机 `lsblk` 显示 `/dev/vda` 为 60 GiB，但 `findmnt /` 仍显示 tmpfs，旧布局仍有 `/nix/persist`；它尚未迁移到新版布局。

备份至少包括 `/home/tau`、`/etc/ssh/ssh_host_ed25519_key` 和 `/home/tau/.config/sops/age/keys.txt`；旧布局还需检查 `/nix/persist` 中的实际持久状态，详见[迁移说明](deployment.md#旧布局迁移到-ext4-根分区)。丢失主机密钥会改变 SSH 主机指纹，丢失 age 私钥会导致服务器无法解密仓库中的 secrets。安装命令会擦盘，已采用新布局的日常更新只运行 `nixos-rebuild`。

按主机分别备份 `/etc/ssh`，并使用独立的 `work/vps-pi/extra-files`、`work/vps-dev/extra-files`、`work/oracle-arm/extra-files`。不同服务器不能复制使用同一 SSH 主机私钥；用户登录密钥和 age admin key 仍可共用。
