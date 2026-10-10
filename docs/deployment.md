# 安装与远程更新

## 首次安装

本机需要支持 flakes 的 Nix、Git、SSH；目标需要 root SSH 或免密码 sudo、可用 kexec。当前模板面向 x86_64 KVM/QEMU VPS。

填写 `users.nix` 的真实完整公钥，核对 `machines/vps/storage.nix` 的整盘路径，仅在服务商要求时声明静态网络。root 与管理员密码锁定，空公钥会触发 NixOS 登录保护断言。

硬件配置由用户控制。`machines/vps/hardware-configuration.nix` 是通用 QEMU 模板，可以保留适用的配置、替换为已有配置，或显式选择由安装器生成。安装入口直接使用锁定的上游 `nixos-anywhere`，不提供探测包装脚本。

```bash
git add .
nix flake check --no-build --no-write-lock-file
```

**安装会清空目标磁盘。** 先备份 `/home`、应用数据及 `/nix/var/lib/sshd` 的主机私钥，保存正确权限与 UID。旧 ext4 布局不能通过重建转换为本仓库布局。

使用已经准备好的硬件配置：

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER
```

选择生成硬件配置时，用以下命令替代上面的命令：

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER \
  --generate-hardware-config nixos-generate-config ./machines/vps/hardware-configuration.nix
```

该参数明确选择 `nixos-generate-config` 后端。锁定的 nixos-anywhere 1.13.0 在构建前执行 `--show-hardware-config --no-filesystems`，写入指定的 Nix 文件；挂载点仍由 disko 管理。省略生成参数时，安装器使用现有文件，仓库也不会自动生成或选择硬件配置。上游会将新增生成文件标记为 Git intent-to-add；安装后仍应审查并提交：

```bash
git diff -- machines/vps/hardware-configuration.nix
git add machines/vps/hardware-configuration.nix
```

私钥、端口与构建位置使用上游参数：

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER \
  -i ~/.ssh/id_ed25519 --ssh-port 22 --build-on auto
nix run .#install -- --help
```

如需生成配置，在上述命令中追加同一生成参数即可。`.#nixos-anywhere` 与默认 `nix run .` 指向同一包。临时 kexec 环境通常使用 SSH 22，服务商防火墙需允许连接。非 Linux 本机需要 Linux 构建器或远端构建。安装完成后使用 `ssh tau@YOUR_SERVER`；root SSH 和密码登录关闭。

## 已安装机器

已有系统迁移时保留当前有效的硬件配置，并迁移实际公钥、磁盘与静态网络参数。如需重新生成，在目标 NixOS 执行：

```bash
sudo nixos-generate-config --show-hardware-config --no-filesystems > hardware-configuration.nix
```

将文件复制回本机对应的 `machines/<name>/hardware-configuration.nix`，审查后提交。该操作不会格式化磁盘。日常重建使用保存的硬件文件：

```bash
nix develop
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 验证第二个 SSH 会话与网络后持久化
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
```

`test` 临时激活，`switch` 同时更新启动默认项，`boot` 仅更新下次启动。管理员通过免密码 sudo 激活系统，Home Manager 同步更新。tmpfs 根不会丢失 `/nix` 的系统代际和 `/boot` 的启动配置。

私钥与端口可写在本机 SSH 配置：

```sshconfig
Host my-vps
  HostName YOUR_SERVER
  User tau
  Port 22
  IdentityFile ~/.ssh/id_ed25519
```

重建使用 `--target-host my-vps`。修改网络、公钥、端口时先 `test`，保留服务商控制台并检查新会话。若失去连接，可通过控制台重启回到上次持久化配置。重装会生成新主机密钥，核验指纹后再更新 known_hosts。
