# 检查与运维

## 修改后验证

两个主机共用 `modules/nixos/base/users.nix` 中的 SSH 公钥和 `secrets/id_ed25519` 中的加密私钥，更换时同时更新。新增文件执行 `git add`；根目录的明文 `id_ed25519` 已被忽略。开发环境包含 nixfmt、sops、Xray 与安装器。

```bash
nix develop
nix fmt
nix flake check --no-build --no-write-lock-file   # 只求值，速度快
nix flake check --no-write-lock-file              # 同时完整构建每台机器的系统
```

`checks` 包含 `nixosConfigurations` 中的每台机器。CI 做同样的两件事：检查格式并构建系统；CI 不解密、不连接 VPS。

## 服务与网络

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
```

修改用户名后替换 Home Manager 服务名。DHCP / RA 应提供地址、路由、DNS；服务商只支持静态配置时应主动在机器入口声明。软件防火墙与服务商防火墙须同时允许 SSH 端口。

## 更新与回滚

```bash
nix flake update nixpkgs-unstable
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 远端紧急回滚
sudo nixos-rebuild switch --rollback
```

也可通过服务商控制台从 GRUB 选择旧代际。GC 每周清理 14 天前的旧代际，GRUB 最多展示 10 个配置；已被 GC 删除的代际不能恢复。网络、公钥、端口和磁盘变更先 `test` 或准备控制台回退路径。

## 状态与备份

```bash
findmnt /
findmnt /boot
df -h
sudo systemctl status nix-gc.timer fstrim.timer
```

根文件系统是硬盘上的 ext4，重启后 `/home/tau`、`/var`、`/etc/ssh` 和 `/nix` 都保留，不需要 impermanence 清单。备份至少包括 `/home/tau`、`/etc/ssh/ssh_host_ed25519_key` 和 `/home/tau/.config/sops/age/keys.txt`；丢失主机密钥会改变 SSH 主机指纹，丢失 age 私钥会导致服务器无法解密仓库中的 secrets。安装命令会擦盘，日常更新只运行 `nixos-rebuild`。
