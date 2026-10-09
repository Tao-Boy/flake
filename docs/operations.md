# 日常运维

## 修改与更新

```bash
nix develop
nix fmt
git add .
nix flake check --no-build
nix build --no-link .#nixosConfigurations.vps.config.system.build.toplevel
nix run .#rebuild -- vps ops@SERVER_IP --action test
# 通过第二个 SSH 会话核对网络、sudo 和服务。
nix run .#rebuild -- vps ops@SERVER_IP --action switch
```

`test` 会实际临时应用配置，但不更新下次启动的默认 generation；`switch` 会应用并持久化；`boot` 只更新下次启动；`dry-activate` 只显示将执行的 activation 动作。修改网络仍可能中断 SSH，因此始终准备服务商控制台。

部署脚本默认在本机构建，通过 SSH 复制到目标后用 sudo 激活。管理员免密码 sudo，不需要把 `ops` 加到 Nix 的 trusted-users。把普通用户加入 trusted-users 会扩大其权限，不应作为常规部署步骤。

直接命令对应：

```bash
nixos-rebuild test --flake .#vps --target-host ops@SERVER_IP --sudo
nixos-rebuild switch --flake .#vps --target-host ops@SERVER_IP --sudo
```

## 更新固定依赖

```bash
nix flake update
git diff -- flake.lock
nix flake check --no-build
nix build --no-link .#nixosConfigurations.vps.config.system.build.toplevel
```

确认变更后提交 lockfile，再按 test/switch 流程应用。自动系统升级默认关闭，避免未经验证的网络或 SSH 变更。

初始 lockfile 的 nixpkgs 与 disko 锁定记录取自上游
[nixos-anywhere 的已提交 lockfile](https://github.com/nix-community/nixos-anywhere/blob/b6be7b277b468d55082584441cbef1fed8530eb3/flake.lock)，保留其真实 rev 与 narHash，并裁剪为本仓库的两项输入。后续由 `nix flake update` 正常维护。

## 回滚

在远端已有 SSH 会话中：

```bash
sudo nixos-rebuild switch --rollback
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

若 test 后失去连接，通过服务商控制台重启通常会进入此前持久化的 generation；若 switch 后失去连接，可从 GRUB 选择以前的 generation，或进入救援环境修复配置。默认用户密码已锁定，控制台本身不提供可用的 root 密码登录。

自动 GC 会删除 14 天前的 generations；长期回滚窗口需要调整 `nix.gc.options` 或保留重要 closure。GC 不是数据备份。

## 常用检查

```bash
systemctl --failed
journalctl -b -p warning
journalctl -u sshd -u fail2ban -u systemd-networkd -f
networkctl status
resolvectl status
ss -tulpn
df -h
free -h
zramctl
sudo fail2ban-client status sshd
sudo nft list ruleset
sudo fstrim -av
```

`fstrim` 依赖服务商暴露 discard 能力，不支持时可在 host 关闭 `services.fstrim.enable`。日志默认限额 256 MiB，coredump 默认不存储。

## 公钥丢失与救援

公钥及 root 密码默认由声明式配置管理，`users.mutableUsers = false`。不要依赖 `passwd` 临时更改后仍会永久保留。

若所有管理员私钥丢失，通过服务商救援镜像挂载根分区，修复仓库中的公钥，再使用 nixos-enter/rebuild 更新系统；或先在救援环境中临时修复 authorized_keys，恢复连接后立即同步声明式配置。具体设备和挂载方式须根据实际磁盘布局确定。

## CI 覆盖

GitHub Actions 在 x86_64 Linux 上执行：

- 在尚未填写公钥的模板上，先验证空公钥拒绝行为，再仅在 CI 临时工作区注入一次性测试公钥。
- 所有 flake 输出与 NixOS assertions 的评估，保留防止管理员锁定的系统断言。
- ShellCheck 与部署工具构建。
- 命令帮助及空 SSH 公钥拒绝检查。
- VPS system toplevel 与 diskoScript 的实际构建。

CI 不连接真实 VPS，不擦除磁盘，不验证服务商网络。应在实际部署前完成脚本的 `--dry-run`，必要时另做 `--vm-test`。
