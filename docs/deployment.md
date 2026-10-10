# 安装与远程更新

## 首次安装

本机需要 flakes 版 Nix、Git、SSH；目标需要 root SSH 或免密码 sudo、可用 kexec。当前模板面向 x86_64 KVM/QEMU VPS，不适用于普通容器 VPS。

填写 `users.nix` 的真实完整公钥；核对 `machines/vps/storage.nix` 的整盘路径；仅在服务商要求时声明静态网络。root 与管理员密码锁定，空公钥会触发 NixOS 登录保护断言。

```bash
git add .
nix flake check --no-build --no-write-lock-file
```

**安装会清空目标磁盘。** 先备份 `/home`、应用数据及 `/nix/var/lib/sshd` 的主机私钥，保存正确权限与 UID。旧 ext4 布局不能通过重建转换为本仓库布局。

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER \
  --generate-hardware-config nixos-facter ./machines/vps/facter.json
```

安装入口是锁定的上游 `nixos-anywhere`，没有独立 shell 包装脚本。硬件探测在构建目标配置前运行；上游会把生成报告标记为 Git intent-to-add，使 Git flake 在本次安装中可见它。安装完成后仍须审查并正式提交报告，供后续可重复构建。

```bash
git add machines/vps/facter.json
git diff --cached -- machines/vps/facter.json
```

报告描述实际硬件，而磁盘布局、地址分配策略仍来自声明式配置。不要复制其他机器的探测报告。

安装的私钥、端口、构建位置使用上游参数：

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER \
  --generate-hardware-config nixos-facter ./machines/vps/facter.json \
  -i ~/.ssh/id_ed25519 --ssh-port 22 --build-on auto
nix run .#install -- --help
```

`.#nixos-anywhere` 与默认 `nix run .` 都指向同一包。临时 kexec 环境通常使用 SSH 22，服务商防火墙需允许连接。非 Linux 本机需要 Linux 构建器或远端构建。安装完成后使用 `ssh tau@YOUR_SERVER`；root SSH 和密码登录关闭。

## 已安装机器

仅为重构迁移时，不要重新执行安装。先在现有系统运行 `nixos-facter`，把报告保存为本机对应的 `machines/<name>/facter.json`，并迁移实际公钥、磁盘与静态网络参数。报告缺失时 QEMU profile 只是通用起点，不能代替真实驱动检查。

```bash
nix develop
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 验证第二个 SSH 会话与网络后持久化
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
```

`test` 仅临时激活，`switch` 同时更新启动默认项，`boot` 仅更新下次启动。管理员通过免密码 sudo 激活系统，Home Manager 同步更新。tmpfs 根不会丢失 `/nix` 的系统代际和 `/boot` 的启动配置。

私钥与端口可写在本机 SSH 配置：

```sshconfig
Host my-vps
  HostName YOUR_SERVER
  User tau
  Port 22
  IdentityFile ~/.ssh/id_ed25519
```

重建使用 `--target-host my-vps`。修改网络、公钥、端口时先 `test`，保留服务商控制台并检查新会话。若失去连接，可通过控制台重启回到上次持久化配置。重装会生成新主机密钥，核验指纹后再更新 known_hosts。
