# 检查与运维

## 修改后验证

先填写真实 SSH 公钥，新增文件执行 `git add`。本地开发环境包含 Nix、nixfmt、statix、deadnix、安装器和硬件探测工具。

```bash
nix develop
nix fmt
nix flake check --no-build --no-write-lock-file
nix build --no-link --no-write-lock-file \
  .#checks.x86_64-linux.quality \
  .#checks.x86_64-linux.evaluation \
  .#checks.x86_64-linux.home-vps \
  .#checks.x86_64-linux.system-vps \
  .#checks.x86_64-linux.disk-vps
```

| 检查 | 内容 |
| --- | --- |
| `install` | 锁定的上游安装器 |
| `quality` | nixfmt 格式、statix、deadnix |
| `evaluation` | 探测报告接入、存储驱动、KVM agent、静态网络覆盖、身份与存储兼容性 |
| `home-<machine>` | 每台机器的 Home Manager 环境 |
| `system-<machine>` | 每台机器的 NixOS 系统 |
| `disk-<machine>` | 每台机器的 disko 脚本构建；不执行格式化 |
| `persistence-vps` | VM 安装、挂载与重启持久化回归测试 |

`.home` 作为原有 vps 用户环境的兼容入口保留。完整 `nix flake check` 会构建所有检查，包括需要 Linux KVM 的 VM 测试：

```bash
nix build --no-link --print-build-logs .#checks.x86_64-linux.persistence-vps
# 或运行全部检查
nix flake check --no-write-lock-file --print-build-logs
```

VM 测试直接定义在 `tests/persistence.nix`，验证 tmpfs / Btrfs / ESP、UID、SSH 主机密钥，以及 `/home`、`/nix` 数据跨重启保留，`/etc`、`/var`、`/root` 测试文件消失。合成 facter 报告仅供求值测试，不是实际硬件配置。

CI 使用这些相同的 Nix 检查；空公钥模板只在 CI 工作区注入临时生成的公钥，不连接 VPS，也不写回仓库。生产配置的空公钥登录保护仍然有效。

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
