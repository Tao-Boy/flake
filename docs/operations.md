# 检查与运维

## 修改后检查

先配置 SSH 公钥，新增文件先 `git add`：

```bash
nix run .#preflight -- vps
nix flake check --no-build --no-write-lock-file
nix build --no-write-lock-file .#checks.x86_64-linux.home
nix build --no-write-lock-file \
  .#nixosConfigurations.vps.config.system.build.toplevel \
  .#nixosConfigurations.vps.config.system.build.diskoScript
```

开发环境提供 nixfmt、statix、deadnix、ShellCheck 和部署工具：

```bash
nix develop
nix fmt
shellcheck scripts/vps.sh
```

CI 先检查部署包/脚本与空公钥拦截，再给未配置模板注入临时测试公钥。随后检查全部 flake 输出、构建用户环境并执行 nvim/git/fzf/bat/eza/rg/fd/btop，最后实际构建系统与分区脚本，确认系统中的 SSH、sudo、网络和诊断工具可用。临时私钥仅存在 CI runner 的工作区。

这些检查验证配置与软件构建；实际网络、磁盘、固件和服务商限制仍需目标上的预检。CI 不连接或安装 VPS。

## 服务和网络

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
```

SSH 被 fail2ban 封禁时通过服务商控制台检查日志，按需解除对应地址。确认 TCP 端口同时被 NixOS 防火墙和服务商防火墙允许。

Home Manager 失败：

```bash
systemctl status home-manager-ops.service
journalctl -u home-manager-ops.service -b
```

管理员改名后相应替换服务名。查看 dotfile 冲突与 `.hm-backup`，整理备份后重新重建。

## 更新与回滚

```bash
# 本机仓库中更新锁文件，检查并提交后远程更新
nix flake update nixpkgs-unstable
nix run .#rebuild -- vps ops@YOUR_SERVER --action test
nix run .#rebuild -- vps ops@YOUR_SERVER --action switch
```

远端紧急回滚：

```bash
sudo nixos-rebuild switch --rollback
```

也可在服务商控制台从 GRUB 选择旧代际。已用 GC 清理的代际无法再回滚。修改网络、公钥、端口时先使用 `test`，保留控制台并验证第二个会话。

自动 GC 每周删除 14 天之前的旧代际；GRUB 最多展示 10 个配置，journald 限额为持久日志 256 MiB、临时日志 64 MiB。zram 默认最多为内存的 50%，Nix 默认单个构建任务，适合小型 VPS，可在主机配置中覆盖。

## 磁盘和备份

```bash
df -h
du -sh /nix/store
nix store optimise
sudo systemctl status nix-gc.timer fstrim.timer
```

重新执行安装会擦盘。Git 只记录声明式配置；数据库、上传文件、运行时秘密、SSH host keys 等数据应另外备份，并实际验证恢复。不要在缺少可用回滚代际时随意清理全部旧系统。
