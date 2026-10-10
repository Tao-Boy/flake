# 检查与运维

## 修改后验证

先填写真实 SSH 公钥，新增文件执行 `git add`。本地开发环境包含 Nix、nixfmt、statix、deadnix、安装器。

```bash
nix develop
nix fmt
nix flake check --no-build --no-write-lock-file
nix develop --command statix check .
nix develop --command deadnix --fail .
nix build --no-link --no-write-lock-file \
  .#nixosConfigurations.vps.config.system.build.toplevel \
  .#nixosConfigurations.vps.config.system.build.diskoScript
```

系统构建包含 Home Manager；构建 disko 脚本不会执行格式化。CI 构建清单中的每台机器，并在机器选用 disko 时构建对应脚本，不运行安装和重启测试，也不需要 KVM。

CI 只在工作区为空公钥模板生成临时公钥，不连接 VPS、不写回仓库。实际配置仍须填写真实公钥。

## 服务与网络

```bash
systemctl --failed
journalctl -b -p warning
systemctl status sshd fail2ban chronyd qemu-guest-agent
networkctl status
resolvectl status
ip -br address
ip route
ss -tulpn
sudo nft list ruleset
sudo fail2ban-client status sshd
systemctl status home-manager-tau.service
```

管理员更名后替换 Home Manager 服务名。DHCP / RA 应提供地址、路由、DNS；服务商只支持静态配置时应主动在机器入口声明。软件防火墙与服务商防火墙须同时允许 SSH 端口。

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
findmnt /home
findmnt /boot
df -h
sudo systemctl status nix-gc.timer fstrim.timer
```

根 tmpfs 上限为内存的 50%，按需占用，并与应用、zram 共享物理内存；大型本机构建可将 Nix `build-dir` 指向 `/nix` 下专用目录。`/nix` 与 `/home` 共享 Btrfs 空间，不代表自动备份。

`/var` 默认易失，数据库、fail2ban 历史、rootful 容器和 ACME 证书需单独规划持久化。SSH 主机私钥持久保存在 `/nix/var/lib/sshd`；备份须保留权限并按秘密处理。安装命令擦盘，日常更新只运行 `nixos-rebuild`。
