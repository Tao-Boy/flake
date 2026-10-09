# 安装与远程更新

在仓库根目录执行命令。本机需要启用 flakes 的 Nix、Git、SSH；目标为 x86_64 VPS，需要 root SSH 和可用的 kexec。

## 准备配置

在 `vars/default.nix` 填写真实完整 SSH 公钥；核对 `hosts/vps/disk-config.nix` 的整盘路径和 `hosts/vps/default.nix` 的网卡、地址与网关。默认配置适合 KVM/QEMU VPS，普通容器 VPS 不适用。

空公钥会触发 NixOS 的登录保护断言，因为 root 和管理员密码已锁定。配置完成后检查：

```bash
git add .
nix flake check --no-build
```

## nixos-anywhere 安装

**安装会清空目标磁盘，先做好备份。** 旧版 ext4 根布局需要重装或另行规划迁移，不能直接用 `nixos-rebuild` 转换。备份 `/home`、应用数据和 SSH 主机密钥；恢复 home 时保持原文件的 UID/GID，并核对管理员默认 UID 1000。

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER
```

脚本直接调用 nixos-anywhere。参数按上游规则填写，例如：

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER \
  -i ~/.ssh/id_ed25519 --ssh-port 22 --build-on auto
```

- `--flake`：选择主机配置，例如 `.#vps`。
- `--target-host`：当前系统的 root SSH 目标。
- `-i`：连接使用的私钥文件。
- `--ssh-port`：当前系统的 SSH 端口。
- `--build-on`：选择 `auto`、`local` 或 `remote` 构建。

所有选项都可以通过帮助查看：

```bash
nix run .#install -- --help
```

也可以直接使用上游包：

```bash
nix run .#nixos-anywhere -- --flake .#vps --target-host root@YOUR_SERVER
```

安装器的临时 kexec 环境通常使用 SSH 22，服务商防火墙需要允许连接。非 Linux 本机需要 Linux 构建器，或采用远端构建。

安装完成后使用配置中的管理员和端口登录：

```bash
ssh ops@YOUR_SERVER
```

新系统的 SSH 主机密钥自动生成在 `/nix/var/lib/sshd`，日常重启会保留指纹。重装擦盘后会生成新密钥；核验新的指纹后再更新 known_hosts。服务商的磁盘、网络和固件要求应在安装前确认。

支持 KVM 的 Linux 上可以运行上游 VM 测试：

```bash
nix run .#nixos-anywhere -- --flake .#vps --vm-test
```

## 标准 nixos-rebuild 更新

```bash
nix develop
nixos-rebuild test --flake .#vps --target-host ops@YOUR_SERVER --sudo
# 用第二个 SSH 会话验证，再持久化
nixos-rebuild switch --flake .#vps --target-host ops@YOUR_SERVER --sudo
```

`test` 临时激活；`switch` 同时更新启动默认配置；`boot` 仅更新下次启动。管理员通过免密码 sudo 激活系统，Home Manager 同步更新。系统代际保留在 `/nix`，启动文件保留在 `/boot`，因此 tmpfs 根不会丢失已 `switch` 的系统配置。手工编辑 `/etc` 或向 `/var` 写入数据则不会跨重启保留。

端口和私钥也可以放到本机 SSH 配置中：

```sshconfig
Host my-vps
  HostName YOUR_SERVER
  User ops
  Port 22
  IdentityFile ~/.ssh/id_ed25519
```

随后使用 `--target-host my-vps`。修改 SSH 端口后同步调整 SSH 配置；网络或端口变更前保留服务商控制台和可用连接。

如果 `test` 后失去连接，可通过控制台重启，回到上次持久化的启动配置。新建 Nix 文件先 `git add`，否则 Git flake 不会包含它。
