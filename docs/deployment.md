# 首次安装与远程更新

所有命令在克隆后的仓库根目录执行。本机需要启用 flakes 的 Nix、Git、SSH；flake 的部署包自动提供 nixos-anywhere、nixos-rebuild 和所需工具。目标仅支持 x86_64。

## 安装前

1. 备份目标数据，确认服务商的救援控制台可用。
2. 在 `vars/default.nix` 填写管理员完整 SSH 公钥。
3. 核对 `hosts/vps/disk-config.nix` 的磁盘和 `hosts/vps/default.nix` 的网络。
4. 准备原系统或救援系统的 root SSH 访问；目标应能执行 kexec，普通容器 VPS 不适用。
5. 通过服务商控制台等可信渠道核对 SSH 主机密钥指纹，将当前目标录入本机 known_hosts。脚本使用严格主机密钥校验。

```bash
git add .
nix run .#preflight -- vps
```

预检直接读取原生配置：SSH AllowUsers、用户 authorizedKeys、SSH 端口、disko 磁盘、GRUB 模式及 networkd 网络信息。验证所有公钥，并强制求值 NixOS 系统和 disko 脚本。

当前快捷入口要求一个管理员、一块磁盘、一个 SSH 端口和 GRUB；复杂安装可扩展预检后使用。空公钥不会被模板或 CI 自动变成真实访问凭据。

## 只读远端预检

```bash
nix run .#install -- vps root@YOUR_SERVER \
  --port 22 --identity ~/.ssh/id_ed25519 --dry-run
```

它确认 root 权限、x86_64 架构、目标块设备和固件，显示磁盘及网络后退出。它不会运行分区或安装命令。

## 执行安装

```bash
nix run .#install -- vps root@YOUR_SERVER \
  --port 22 --identity ~/.ssh/id_ed25519 --build-on auto
```

再次通过预检后，在交互终端输入显示的完整 `ERASE <SSH目标> <磁盘>`。随后 nixos-anywhere 使用 `--flake .#vps` 与 disko 清空磁盘、创建分区并安装。

`--build-on` 支持 `auto`、`local`、`remote`。远端内存较小时可用本机 Linux 或远程 Linux builder 构建；非 Linux 本机需要合适的 Linux 构建器，或选择 `remote`。

`--port` 是当前原系统端口；临时 kexec 安装器使用 22。服务商外部防火墙必须允许该阶段所需连接，nixos-anywhere 自行管理临时安装凭据。安装完成后按配置端口登录管理员，root SSH 已关闭。

```bash
ssh -p 22 ops@YOUR_SERVER
sudo systemctl --failed
```

重装会更换 SSH 主机密钥。先通过控制台核验新指纹，再更新 known_hosts；不要盲目忽略校验。服务商 DHCP、静态路由、EFI、VirtIO 等要求决定模板是否可直接用于实际机器。

也可先在支持 KVM 的 Linux 上运行上游 VM 安装测试（仍需有效公钥）：

```bash
nix run .#nixos-anywhere -- --flake .#vps --vm-test
```

## 日常更新

```bash
nix run .#rebuild -- vps ops@YOUR_SERVER --identity ~/.ssh/id_ed25519
# 用第二个 SSH 会话检查网络、登录、服务；成功后持久化
nix run .#rebuild -- vps ops@YOUR_SERVER \
  --identity ~/.ssh/id_ed25519 --action switch
```

默认 `test` 临时激活；`switch` 同时更新启动默认配置；`boot` 仅更新下次启动；还支持 `dry-activate` 与 `build`。更新通过管理员免密码 sudo 激活，Home Manager 同步切换。

改 SSH 端口时，在首次更新中传入当前端口，验证新的连接后再使用新端口。`test` 导致连接中断时，可通过控制台重启回到上次持久化的启动配置。更新操作同样不会自动改写锁文件。

## 配置未生效

flake 只包含 Git 已跟踪文件；新建文件必须先 `git add`。预检显示本地配置，并不会替你确认服务商分配的实际磁盘、地址或网关。网络改动前保留控制台和可用的 SSH 会话。
