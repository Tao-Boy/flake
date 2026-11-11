# 安装与远程更新

## 密钥

| 密钥 | 保存位置 | 用途 |
| --- | --- | --- |
| 用户 SSH 密钥 | 公钥直接写在 `modules/nixos/base/users.nix`；私钥密文在 `secrets/id_ed25519`，运行时在 `/run/secrets/id_ed25519` | `vps` 和 `oracle-arm` 共用，用于 `tau` 登录和出站 SSH；运行时私钥属于 `tau`，权限为 `0600` |
| pi-web 环境文件 | `secrets/server.env`（SOPS dotenv 密文），运行时在 `/run/secrets/pi-web.env`，root `0400` | pi-web 登录密码及运行时环境变量，由 Podman 读取 |
| Ignis Basic Auth | `secrets/ignis.htpasswd`（SOPS 密文），运行时由 sops-nix 提供给 Nginx | 保护 `ob.nullcode.cc` 上的 Ignis vault |
| 管理密钥（age） | 本机 `~/.config/sops/age/keys.txt`；服务器 `/home/tau/.config/sops/age/keys.txt` | 本机用 `sops` 创建、编辑 `secrets/`；服务器上 sops-nix 开机时用它解密 |
| 服务器 SSH 主机密钥 | 服务器 `/etc/ssh/ssh_host_ed25519_key` | SSH 主机身份，不参与解密 |

`.sops.yaml` 中只有 `admin` 一把 age 公钥，`modules/nixos/server/sops.nix` 只读取服务器上的 `keys.txt`（`sshKeyPaths = [ ]`），**文件缺失时激活失败**。用户 SSH 私钥只以 SOPS 密文进入仓库；age 私钥、SSH 主机私钥和明文用户私钥由你自己保存和备份。

## 准备

本机需要支持 flakes 的 Nix、Git、SSH；目标需要 root SSH 或免密码 sudo、可用 kexec。配置同时支持 x86_64 KVM/QEMU VPS 和 Oracle Cloud Ampere aarch64 实例。

1. 核对 `modules/nixos/base/users.nix` 中直接配置的 SSH 公钥。更换统一用户密钥时，把新公钥填到该模块，将配套的明文私钥临时保存为仓库根目录的 `id_ed25519`，再用现有 age 公钥加密：

   ```bash
   nix develop
   chmod 600 id_ed25519
   sops encrypt --input-type binary --output-type binary \
     --filename-override secrets/id_ed25519 id_ed25519 > secrets/id_ed25519
   ```

   根目录的 `id_ed25519` 已在 `.gitignore` 中排除；提交公钥配置和 `secrets/id_ed25519` 密文即可。`modules/nixos/server/ssh.nix` 会将私钥解密到 `/run/secrets/id_ed25519`，并为 `tau` 配置 `IdentityFile` 和 `IdentitiesOnly yes`。新管理密钥须先完成下一步再加密。

   核对目标主机的磁盘文件：VPS 使用 `hosts/vps/disko-fs.nix`，Oracle ARM 使用 `hosts/oracle-arm/disko-fs.nix`。
2. 生成管理密钥（已有时跳过），把输出的公钥填入 `.sops.yaml` 的 `admin`：

   ```bash
   nix develop
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

3. 生成服务器的 SSH 主机密钥，放在安装时要复制到服务器的 `work/extra-files` 中。主机密钥只用于 SSH 身份，预先生成可以固定主机指纹：

   ```bash
   umask 022
   mkdir -p work/extra-files/etc/ssh
   ssh-keygen -t ed25519 -N "" -C vps -f work/extra-files/etc/ssh/ssh_host_ed25519_key
   find work/extra-files -type d -exec stat -c '%a %n' {} +   # 每个目录都应为 755
   ```

   同一台服务器的 age 私钥放在持久化的用户家目录：

   ```bash
   mkdir -p work/extra-files/home/tau/.config/sops/age
   install -m 600 ~/.config/sops/age/keys.txt work/extra-files/home/tau/.config/sops/age/keys.txt
   chmod 700 work/extra-files/home/tau
   ```

   安装时 `work/extra-files` 中的目录权限会原样复制到服务器，根目录下的 `home`、`etc` 和 `nix` 必须保持可遍历。很多系统的默认 umask 是 `002` 或 `077`，因此先执行 `umask 022`。`ssh-keygen` 本身会把私钥设为 `600`。

4. 按[代理说明](proxy.md)检查 `secrets/client.json` 和 `secrets/server.json`。更换 `.sops.yaml` 中的管理公钥后，重新加密已有文件，并把新的 `keys.txt` 放到服务器上：

   ```bash
   sops updatekeys secrets/client.json
   sops updatekeys secrets/server.json
   sops updatekeys secrets/server.env
   sops updatekeys secrets/id_ed25519
   sops updatekeys secrets/ignis.htpasswd
   ```

5. 检查：

   ```bash
   git add .
   nix flake check --no-build --no-write-lock-file
   ```

`work/extra-files/etc/ssh/ssh_host_ed25519_key.pub` 可以写入本机 `~/.ssh/known_hosts`（`YOUR_SERVER ssh-ed25519 AAAA...`），连接时不再需要人工核对指纹。

## 首次安装

**安装会清空目标磁盘。** 先备份服务器上的数据。

```bash
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER \
  --extra-files "$PWD/work/extra-files" --chown /home/tau 1000:100 \
  --build-on local
```

`extra-files` 复制后默认归 root 所有；`--chown` 把家目录交还给 `tau`（UID 1000，`users` 组 GID 100），否则普通用户无法写入自己的家目录。

需要让安装器生成硬件配置时，追加：

```bash
  --generate-hardware-config nixos-generate-config ./hosts/vps/hardware-configuration.nix
```

生成后审查并提交 `hosts/vps/hardware-configuration.nix`。其他参数（私钥、端口）见 `nix run .#install -- --help`。

安装过程：kexec 进入临时系统 → disko 格式化并挂载 ext4 根分区到 `/mnt` → 复制系统 → 把 `work/extra-files` 复制到 `/mnt`，主机密钥落到 `/mnt/etc/ssh/`、age 私钥落到 `/mnt/home/tau/.config/sops/age/` → `nixos-install` → 重启。首次开机时 age 私钥已经在磁盘上，sops-nix 可以直接解密。

安装完成后用 `ssh tau@YOUR_SERVER` 登录；root SSH 和密码登录关闭。把 `work/extra-files` 中的主机私钥移到安全的地方备份，重装时放回同一路径即可保持主机指纹和解密能力不变。

`--build-on local` 在本机构建系统，目标进入 kexec 后不需要再下载构建。国内网络下在 LiveCD 本机安装见[代理说明](proxy.md#livecd-本机安装)。

## Oracle Cloud Ampere ARM

Oracle ARM 当前只启用基础系统、SSH/SOPS、Xray Reality 服务端和 Podman Ignis；Home Manager 与通用维护模块暂未导入。Xray 使用 `nixpkgs-unstable`。Ignis 使用 `docker.io/nobbe/ignis:latest`，不锁定镜像 digest，并在每次容器启动时拉取该标签的最新镜像（`pull = "always"`）；上游发布新版后，在服务器执行 `sudo systemctl restart podman-ignis.service` 即可更新。持久数据位于 `/home/tau/ignis/`：`vaults/` 保存笔记库，`data/` 保存插件管理与同步等状态，`obsidian-app/` 保存应用缓存；镜像和容器可写层仍位于 `/var/lib/containers/storage`。Nginx 在 `ob.nullcode.cc` 终止 TLS、启用 Basic Auth 和 WebSocket 代理。认证哈希保存在 `secrets/ignis.htpasswd` 的 SOPS 密文中，不要把明文密码写进 Nix 配置。

部署前确认 `ob.nullcode.cc` 的 DNS 指向实例公网地址，并在 OCI 网络安全列表/NSG 放行 TCP 80、443；Xray 的 TCP 2333 也需按客户端访问范围开放。ACME 首次签发证书需要公网可达的 80/443。更换 Ignis 密码时，在本机安全终端交互生成 bcrypt 哈希并直接加密写入 SOPS 文件：

```bash
nix shell nixpkgs#apacheHttpd nixpkgs#sops -c bash -c \
  'htpasswd -nB -C 12 admin | sops encrypt --input-type binary --output-type binary --filename-override secrets/ignis.htpasswd --output secrets/ignis.htpasswd /dev/stdin'
```

Oracle ARM 主机入口是 `.#oracle-arm`，目标平台为 `aarch64-linux`。默认磁盘写为 `/dev/sda`，但 OCI 实例的设备名可能因镜像和实例类型不同而变化；安装前在临时系统中执行 `lsblk`，再修改 [hosts/oracle-arm/disko-fs.nix](/home/tau/.config/flake/hosts/oracle-arm/disko-fs.nix:5)。

从 x86_64 工作站安装时，优先让目标机自己构建 ARM 系统：

```bash
nix run .#install -- --flake .#oracle-arm --target-host root@YOUR_ORACLE_IP \
  --extra-files "$PWD/work/extra-files" --chown /home/tau 1000:100 \
  --build-on remote
```

如果 Oracle 实例尚未允许 root SSH，需要先在实例控制台或现有系统中准备临时 root SSH 访问。安装会擦除 OCI 启动卷；确认磁盘设备后再执行。需要重新生成硬件文件时使用：

```bash
  --generate-hardware-config nixos-generate-config ./hosts/oracle-arm/hardware-configuration.nix
```

ARM 主机也可以使用 `nixos-rebuild` 远程更新：

```bash
nixos-rebuild test --flake .#oracle-arm --target-host tau@YOUR_ORACLE_IP --sudo
nixos-rebuild switch --flake .#oracle-arm --target-host tau@YOUR_ORACLE_IP --sudo
```


原先已经在 `/var/lib/ignis` 保存数据的机器，切换配置前需在 Oracle 主机上停止 Ignis 并复制数据。以下步骤适用于新路径尚无数据的首次迁移；若 `/home/tau/ignis` 已有数据，先备份并核对目录，避免覆盖同名文件：

```bash
sudo systemctl stop podman-ignis.service
sudo install -d -m 0750 -o tau -g users /home/tau/ignis
sudo cp -a /var/lib/ignis/. /home/tau/ignis/
sudo chown -R tau:users /home/tau/ignis
```

然后执行上面的 `nixos-rebuild test` / `switch`，再运行 `sudo systemctl start podman-ignis.service`，检查原笔记库、插件和同步状态。旧目录保留用于回退；首次安装会自动创建新的空目录，无需复制。旧目录保留用于回退；首次安装会自动创建新的空目录，无需复制。

旧版使用根 tmpfs、独立的 `/nix` 和 `/nix/persist` 保存状态。新布局会格式化目标整盘，不能通过普通重建转换；先备份旧系统的 `/home/tau`、`/etc/ssh` 和 `/nix/persist/home/tau/.config/sops/age/keys.txt`，再重新安装，最后把用户数据和 age 私钥放回 `/home/tau`。

## pi-web 切换到 Podman

VPS 的 pi-web 由 `podman-pi-web.service` 管理，镜像与持久化说明见[可选服务](services.md)。环境文件已经加密保存为 `secrets/server.env`，由 SOPS 在运行时解密到 `/run/secrets/pi-web.env`，Podman 启动时读取；服务器只需准备现有的 age 私钥，无需另外复制明文 `server.env`。后续使用 `sops edit secrets/server.env` 修改，保留 `PI_WEB_PASSWORD` 等变量，并使用不带 `export` 或值两侧引号的 `KEY=value` 格式。

已运行旧版 npm 用户服务的机器，在 VPS 上以 `tau` 停止旧服务，释放 30141 端口：

```bash
systemctl --user disable --now pi-web.service
```

随后按下方的日常更新命令重建 VPS。Home Manager 会移除旧用户服务，NixOS 会启用 Podman 容器。检查新服务及 HTTPS 访问：

```bash
sudo systemctl status podman-pi-web.service
sudo journalctl -u podman-pi-web.service -n 100 --no-pager
curl -I https://pi.nullcode.cc
```

工作区 `/home/tau/pi-workspace` 由系统自动创建，容器只挂载这个目录，agent 配置、会话和项目分别保存在其中。旧的 `~/.pi`、skills 和项目保留在原处；需要复用时，应选择性复制普通文件到工作区，并避免依赖工作区外路径或指向 `/nix/store` 的符号链接。旧会话记录包含绝对工作路径，不会因复制会话文件而自动改成新路径；模型凭据也可在 Web 的 Models 面板重新配置。宿主机旧的 npm 安装可另行保留或卸载，容器不依赖它。

## 日常更新

```bash
nix develop
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 验证第二个 SSH 会话与网络后保存为启动默认配置
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
```

`test` 临时激活，`switch` 同时更新启动默认项，`boot` 仅更新下次启动。重建只推送新系统，`secrets/` 都是密文，服务器用已有的 age 私钥解密，不需要再上传任何文件。

私钥与端口可写在本机 SSH 配置：

```sshconfig
Host my-vps
  HostName YOUR_SERVER
  User tau
  Port 22
  IdentityFile ~/.ssh/id_ed25519
```

重建使用 `--target-host my-vps`。修改网络、公钥、端口时先 `test`，保留服务商控制台并检查新会话。失去连接时，可通过控制台重启回到上次 `switch` 的配置。
