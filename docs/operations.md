# 检查与运维

## 修改后验证

先填写真实 SSH 公钥，新增文件执行 `git add`。开发环境包含 nixfmt、sops、Xray 与安装器。

```bash
nix develop
nix fmt
nix flake check --no-build --no-write-lock-file   # 只求值，速度快
nix build --no-link .#nixosConfigurations.vps.config.system.build.toplevel
```

最后一条完整构建系统，包含 Home Manager。CI 做同样的两件事：检查 Nix 文件格式、构建 vps 系统；CI 不解密、不连接 VPS。

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

也可通过服务商控制台从 GRUB 选择旧代际。GC 每周清理 14 天前的旧代际，GRUB 最多展示 10 个配置；已被 GC 删除的代际不能恢复。网络 / 公钥 / 端口变更先 `test` 并验证第二个会话。

## 状态与备份

```bash
findmnt /
findmnt /nix
findmnt /home/tau   # 来自 /nix/persist/home/tau
ls /nix/persist
findmnt /boot
df -h
sudo systemctl status nix-gc.timer fstrim.timer
```

根 tmpfs 上限为内存的 50%，按需占用，并与应用、zram 共享物理内存。写在 `/`、`/etc`、`/var` 等位置、但不在 `modules/impermanence.nix` 清单中的文件，重启后消失；新增有状态的服务时把它的目录加入清单。

需要备份的是 `/nix/persist`。其中的 SSH 主机私钥同时用于解密 `secrets/`，丢失后只能用本机的管理密钥重新加密给新主机密钥。安装命令擦盘，日常更新只运行 `nixos-rebuild`。
