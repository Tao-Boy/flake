# 安装与远程更新

## 两把密钥

| 密钥 | 保存位置 | 用途 |
| --- | --- | --- |
| 管理密钥（age） | 本机 `~/.config/sops/age/keys.txt` | 你在本机用 `sops` 创建、编辑 `secrets/` |
| 服务器 SSH 主机密钥 | 服务器 `/nix/persist/etc/ssh/ssh_host_ed25519_key` | SSH 主机身份；sops-nix 开机时用它解密 `secrets/` |

`.sops.yaml` 中的 `admin` 和 `server_ssh` 是两把密钥对应的公钥，`secrets/` 中的文件同时为两者加密。两把私钥都由你自己保存和备份，不进入仓库。

## 准备

本机需要支持 flakes 的 Nix、Git、SSH；目标需要 root SSH 或免密码 sudo、可用 kexec。当前配置面向 x86_64 KVM/QEMU VPS。

1. 在 `user.nix` 填写自己的 SSH 公钥，核对 `machines/vps/storage.nix` 的目标整盘。
2. 生成管理密钥（已有时跳过），把输出的公钥填入 `.sops.yaml` 的 `admin`：

   ```bash
   nix develop
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

3. 生成服务器的 SSH 主机密钥，放在安装时要复制到服务器的目录 `work/extra-files` 中（`work/` 不会被 Git 跟踪）。把 `ssh-to-age` 输出的公钥填入 `.sops.yaml` 的 `server_ssh`：

   ```bash
   mkdir -p work/extra-files/nix/persist/etc/ssh
   ssh-keygen -t ed25519 -N "" -C vps -f work/extra-files/nix/persist/etc/ssh/ssh_host_ed25519_key
   ssh-to-age -i work/extra-files/nix/persist/etc/ssh/ssh_host_ed25519_key.pub
   ```

   不要设置 `umask 077`：安装时目录权限会原样复制到服务器，`/nix` 必须保持 `755`。`ssh-keygen` 本身会把私钥设为 `600`。

4. 按[代理说明](proxy.md)创建 `secrets/xray.json`。修改 `.sops.yaml` 中的公钥后，重新加密已有文件：

   ```bash
   sops updatekeys secrets/xray.json
   ```

5. 检查：

   ```bash
   git add .
   nix flake check --no-build --no-write-lock-file
   ```

`work/extra-files/nix/persist/etc/ssh/ssh_host_ed25519_key.pub` 可以写入本机 `~/.ssh/known_hosts`（`YOUR_SERVER ssh-ed25519 AAAA...`），连接时不再需要人工核对指纹。

## 首次安装

**安装会清空目标磁盘。** 先备份服务器上的数据。

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER \
  --extra-files "$PWD/work/extra-files" --build-on local
```

需要让安装器生成硬件配置时，追加：

```bash
  --generate-hardware-config nixos-generate-config ./machines/vps/hardware-configuration.nix
```

生成后审查并提交 `machines/vps/hardware-configuration.nix`。其他参数（私钥、端口）见 `nix run .#install -- --help`。

安装过程：kexec 进入临时系统 → disko 分区并挂载到 `/mnt` → 复制系统 → 把 `work/extra-files` 复制到 `/mnt`，主机密钥落到 `/mnt/nix/persist/etc/ssh/` → `nixos-install` → 重启。首次开机时密钥已经在磁盘上，sops-nix 可以直接解密。

安装完成后用 `ssh tau@YOUR_SERVER` 登录；root SSH 和密码登录关闭。把 `work/extra-files` 中的主机私钥移到安全的地方备份，重装时放回同一路径即可保持主机指纹和解密能力不变。

`--build-on local` 在本机构建系统，目标进入 kexec 后不需要再下载构建。国内网络下在 LiveCD 本机安装见[代理说明](proxy.md#livecd-本机安装)。

## 从旧版布局迁移

旧版使用独立的 `/home` 分区，现在只有 `/boot` 和 `/nix` 两个分区，家目录保存在 `/nix/persist/home/tau`。分区布局不能通过重建转换，需要备份 `/home` 后重装，再把数据放回 `/home/tau`。想保留原来的主机指纹时，把服务器现有的主机密钥复制到 `work/extra-files/nix/persist/etc/ssh/` 代替新生成的密钥，再用 `ssh-to-age` 计算公钥。

## 日常更新

```bash
nix develop
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 验证第二个 SSH 会话与网络后保存为启动默认配置
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
```

`test` 临时激活，`switch` 同时更新启动默认项，`boot` 仅更新下次启动。重建只推送新系统，`secrets/` 都是密文，服务器用已有的主机密钥解密，不需要再上传任何文件。

私钥与端口可写在本机 SSH 配置：

```sshconfig
Host my-vps
  HostName YOUR_SERVER
  User tau
  Port 22
  IdentityFile ~/.ssh/id_ed25519
```

重建使用 `--target-host my-vps`。修改网络、公钥、端口时先 `test`，保留服务商控制台并检查新会话。失去连接时，可通过控制台重启回到上次 `switch` 的配置。
