# 检查与运维

## 修改后检查

先填 SSH 公钥，新增文件先 `git add`：

```bash
nix flake check --no-build
nix build --no-link .#checks.x86_64-linux.install
nix build --no-link .#checks.x86_64-linux.home
nix build --no-link \
  .#nixosConfigurations.vps.config.system.build.toplevel \
  .#nixosConfigurations.vps.config.system.build.diskoScript
```

`checks` 只包含两个构建目标：`install` 和 `home`。安装包由 `writeShellApplication` 生成，构建时自动运行 ShellCheck；`home` 构建 Home Manager 环境。`nix flake check` 会构建这些目标，`--no-build` 只执行求值。

完整检查也会求值 `nixosConfigurations.vps`，因此 NixOS 自带的登录保护断言仍会执行。若提示 root / wheel 用户缺少密码或 SSH 公钥，在 `vars/default.nix` 填写真实完整公钥即可。

## 开发工具

```bash
nix develop
nix fmt
shellcheck scripts/vps.sh
```

CI 验证安装器帮助，求值 flake，并构建用户环境、系统和磁盘脚本。空公钥模板会在 CI 工作区注入临时公钥，不会写回仓库或连接 VPS。

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
nix develop
nixos-rebuild test --flake .#vps --target-host ops@YOUR_SERVER --sudo
nixos-rebuild switch --flake .#vps --target-host ops@YOUR_SERVER --sudo
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
