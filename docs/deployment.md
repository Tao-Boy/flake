# 安装与远程更新

## 首次安装

本机需要支持 flakes 的 Nix、Git、SSH；目标需要 root SSH 或免密码 sudo、可用 kexec。当前模板面向 x86_64 KVM/QEMU VPS。

填写 `user.nix` 的真实完整公钥，核对 `machines/vps/storage.nix` 的整盘路径，仅在服务商要求时声明静态网络。root 与用户 `tau` 都没有密码；不填公钥时 NixOS 会拒绝构建，以免装好后无法登录。

VPS 默认启用 Xray。先按[代理说明](proxy.md)用 `sops` 创建完整的 Xray JSON 并填写实际节点，提交 `.sops.yaml` 与 `secrets/xray.json`，并准备安装所需的 age 私钥副本：

```bash
umask 077
mkdir -p work/extra-files/home/tau/.config/sops/age
install -m 600 ~/.config/sops/age/keys.txt work/extra-files/home/tau/.config/sops/age/keys.txt
```

age 私钥由你自己保存，不进入仓库；丢失后无法解密 `secrets/`，请另行备份。安装后服务器上的副本位于 `/home/tau/.config/sops/age/keys.txt`，与本机 sops 的默认位置相同；安装命令中的 `--chown /home/tau 1000:100` 让复制进去的文件归 `tau`（UID 1000、`users` 组 100）所有，因此在服务器上也能直接运行 `sops`。使用其他位置的私钥时替换源路径。`work/` 中的副本不会被 Git 跟踪，安装后删除。加密、代理开关以及国内网络下的 LiveCD 本机安装见[代理说明](proxy.md)。

### SSH 主机密钥

主机密钥也用同一把 age 公钥加密进仓库（`secrets/ssh_host_ed25519_key`），开机时由 sops-nix 解密到 `/run/secrets/`，重装后指纹不变。在开发环境中生成并加密：

```bash
nix develop
umask 077
mkdir -p work/hostkey
ssh-keygen -t ed25519 -N "" -C vps -f work/hostkey/ssh_host_ed25519_key
sops encrypt --filename-override secrets/ssh_host_ed25519_key \
  work/hostkey/ssh_host_ed25519_key > secrets/ssh_host_ed25519_key
git add secrets/ssh_host_ed25519_key
```

`work/hostkey/ssh_host_ed25519_key.pub` 是主机公钥，可以写入本机的 `~/.ssh/known_hosts`（`YOUR_SERVER ssh-ed25519 AAAA...`），之后连接时不再需要人工核对指纹；明文私钥用完后删除。系统只使用 ed25519 主机密钥。查看或更换时使用 `sops decrypt secrets/ssh_host_ed25519_key`，或按上面的命令重新生成。

硬件配置由用户控制。`machines/vps/hardware-configuration.nix` 是通用 QEMU 模板，可以保留适用的配置、替换为已有配置，或显式选择由安装器生成。安装入口直接使用锁定的上游 `nixos-anywhere`，不提供探测包装脚本。

```bash
git add .
nix flake check --no-build --no-write-lock-file
```

**安装会清空目标磁盘。** 先备份 `/home` 和应用数据，并确认本机仍保存着 age 私钥，保存正确权限与 UID。本布局使用独立的 ext4 `/nix` 和 `/home` 分区，`/home` 默认 4 GiB，其余可用空间用于 `/nix`。安装前根据现有数据量调整 `storage.nix` 中的容量设置。已有文件系统和分区布局不能通过普通重建自动转换；需要备份、重新分区安装并恢复数据。

使用已经准备好的硬件配置：

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER \
  --extra-files "$PWD/work/extra-files" --chown /home/tau 1000:100 --build-on local
```

选择生成硬件配置时，用以下命令替代上面的命令：

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER \
  --extra-files "$PWD/work/extra-files" --chown /home/tau 1000:100 --build-on local \
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
  --extra-files "$PWD/work/extra-files" --chown /home/tau 1000:100 --build-on local \
  -i ~/.ssh/id_ed25519 --ssh-port 22
nix run .#install -- --help
```

如需生成配置，在上述命令中追加同一生成参数即可。临时 kexec 环境通常使用 SSH 22，服务商防火墙需允许连接。非 Linux 本机需要 Linux 构建器或远端构建。安装完成后使用 `ssh tau@YOUR_SERVER`；root SSH 和密码登录关闭。

上述 `--build-on local` 使用安装命令所在的独立 Linux 构建机，避免目标进入 kexec 后再依赖 LiveCD 临时代理构建。代理环境不会自动传入目标的 kexec 环境；同一台 LiveCD 本机安装采用[代理说明中的 disko 与 nixos-install 流程](proxy.md)。

## 已安装机器

### 从旧版本迁移密钥

旧版本把 SSH 主机密钥放在 `/nix/var/lib/sshd`，age 私钥放在 `/nix/var/lib/sops-nix/key.txt`。重建到当前配置**之前**完成两步，否则 Xray 配置无法解密，主机密钥也会变化（客户端提示指纹变化）。

在本机把服务器现有的主机私钥加密进仓库，保持指纹不变：

```bash
nix develop
ssh tau@YOUR_SERVER sudo cat /nix/var/lib/sshd/ssh_host_ed25519_key \
  | sops encrypt --filename-override secrets/ssh_host_ed25519_key > secrets/ssh_host_ed25519_key
git add secrets/ssh_host_ed25519_key
```

在服务器上把 age 私钥复制到新位置：

```bash
# 以 tau 身份执行，文件自然归 tau 所有。
mkdir -p ~/.config/sops/age
sudo cat /nix/var/lib/sops-nix/key.txt > ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

重建并确认新的 SSH 会话正常、`systemctl status xray` 运行后，再删除 `/nix/var/lib/sshd` 和 `/nix/var/lib/sops-nix`。旧的 RSA 主机密钥不再使用；客户端的 `known_hosts` 中若只记录了 RSA 密钥，需要更新一次。

### 日常更新

已有系统更新时保留当前有效的硬件配置，并迁移实际公钥、磁盘与静态网络参数。若磁盘仍采用此前的子卷布局，应按首次安装流程备份并迁移至 ext4；下面的重建命令不会转换文件系统。如需重新生成，在目标 NixOS 执行：

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

`test` 临时激活，`switch` 同时更新启动默认项，`boot` 仅更新下次启动。用户 `tau` 通过免密码 sudo 激活系统，Home Manager 同步更新。tmpfs 根不会丢失 `/nix` 的系统代际和 `/boot` 的启动配置。

私钥与端口可写在本机 SSH 配置：

```sshconfig
Host my-vps
  HostName YOUR_SERVER
  User tau
  Port 22
  IdentityFile ~/.ssh/id_ed25519
```

重建使用 `--target-host my-vps`。修改网络、公钥、端口时先 `test`，保留服务商控制台并检查新会话。若失去连接，可通过控制台重启回到上次持久化配置。重装会生成新主机密钥，核验指纹后再更新 known_hosts。
