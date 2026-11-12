# 安装与远程更新

## 密钥

| 密钥 | 保存位置 | 用途 |
| --- | --- | --- |
| 用户 SSH 密钥 | 公钥直接写在 `modules/nixos/base/users.nix`；私钥密文在 `secrets/id_ed25519`，运行时在 `/run/secrets/id_ed25519` | `vps-pi`、`vps-dev` 和 `oracle-arm` 共用，用于 `tau` 登录和出站 SSH；运行时私钥属于 `tau`，权限为 `0600` |
| pi-web 环境文件 | `secrets/server.env`（SOPS dotenv 密文），运行时在 `/run/secrets/pi-web.env`，root `0400` | 仅 `vps-pi` 使用：pi-web 登录密码及运行时环境变量，由 Podman 读取 |
| Ignis Basic Auth | `secrets/ignis.htpasswd`（SOPS 密文），运行时由 sops-nix 提供给 Nginx | 仅 `oracle-arm` 使用：保护 `ob.nullcode.cc` 上的 Ignis vault |
| 管理密钥（age） | 本机 `~/.config/sops/age/keys.txt`；服务器 `/home/tau/.config/sops/age/keys.txt` | 本机用 `sops` 创建、编辑 `secrets/`；服务器上 sops-nix 开机时用它解密 |
| 服务器 SSH 主机密钥 | 服务器 `/etc/ssh/ssh_host_ed25519_key` | SSH 主机身份，不参与解密 |

`.sops.yaml` 中只有 `admin` 一把 age 公钥，`modules/nixos/server/sops.nix` 只读取服务器上的 `keys.txt`（`sshKeyPaths = [ ]`），**文件缺失时激活失败**。用户 SSH 私钥只以 SOPS 密文进入仓库；age 私钥、SSH 主机私钥和明文用户私钥由你自己保存和备份。

三台主机可共用用户登录密钥和 age admin key；**不同服务器不能复制使用同一 SSH 主机私钥**。安装文件按主机隔离到 `work/vps-pi/extra-files`、`work/vps-dev/extra-files` 和 `work/oracle-arm/extra-files`，不能把一台服务器的整个目录直接复制给另一台。`vps-dev` 仅使用共用 SSH 和 Xray 客户端 secrets，不导入 pi-web 或 Ignis 等应用 secrets。

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

   核对目标主机的磁盘文件：`vps-pi` 使用 `hosts/vps-pi/disko-fs.nix`（`/dev/vda`），`vps-dev` 使用 `hosts/vps-dev/disko-fs.nix`（`/dev/sda`），Oracle ARM 使用 `hosts/oracle-arm/disko-fs.nix`（默认 `/dev/sda`）。
2. 生成管理密钥（已有时跳过），把输出的公钥填入 `.sops.yaml` 的 `admin`：

   ```bash
   nix develop
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

3. 为每台服务器单独生成 SSH 主机密钥，放在安装时要复制到该服务器的目录中。下面以 `vps-pi` 为例；准备其他主机时，将 `install_host` 改为 `vps-dev` 或 `oracle-arm`，分别执行。重装同一台服务器时恢复其原有主机密钥，不要重新生成或覆盖：

   ```bash
   install_host=vps-pi
   extra_files="$PWD/work/$install_host/extra-files"
   umask 022
   mkdir -p "$extra_files/etc/ssh"
   ssh-keygen -t ed25519 -N "" -C "$install_host" -f "$extra_files/etc/ssh/ssh_host_ed25519_key"
   find "$extra_files" -type d -exec stat -c '%a %n' {} +   # 每个目录都应为 755
   ```

   把可共用的 age admin 私钥放入该主机对应的用户家目录：

   ```bash
   mkdir -p "$extra_files/home/tau/.config/sops/age"
   install -m 600 ~/.config/sops/age/keys.txt "$extra_files/home/tau/.config/sops/age/keys.txt"
   chmod 700 "$extra_files/home/tau"
   ```

   安装时 `work/<主机>/extra-files` 中的目录权限会原样复制到服务器，根目录下的 `home`、`etc` 和 `nix` 必须保持可遍历。很多系统的默认 umask 是 `002` 或 `077`，因此先执行 `umask 022`。`ssh-keygen` 本身会把私钥设为 `600`。

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

`work/<主机>/extra-files/etc/ssh/ssh_host_ed25519_key.pub` 可以写入本机 `~/.ssh/known_hosts`（`YOUR_SERVER ssh-ed25519 AAAA...`），连接时不再需要人工核对指纹。每个地址应对应各自主机的公钥。

## 首次安装

**安装会清空目标磁盘。** 先备份服务器上的数据。以下示例安装 `vps-pi`，保留原 VPS 的 Home Manager、Xray 客户端、pi-web、Podman、Nginx/ACME 等全部服务；开发机使用下方的 [`vps-dev` 安装说明](#vps-dev-开发服务器)。

当前本机 `lsblk` 确认 `/dev/vda` 为 60 GiB，但根 `/` 仍是 tmpfs，旧布局仍有 `/nix/persist`，并未部署仓库新版 ext4 根布局。对此必须先完成[旧布局迁移](#旧布局迁移到-ext4-根分区)中的备份和恢复准备，再执行安装；普通重建不能转换该布局。

```bash
nix run .#install -- --flake .#vps-pi --target-host root@YOUR_PI_SERVER \
  --extra-files "$PWD/work/vps-pi/extra-files" --chown /home/tau 1000:100 \
  --build-on local
```

`extra-files` 复制后默认归 root 所有；`--chown` 把家目录交还给 `tau`（UID 1000，`users` 组 GID 100），否则普通用户无法写入自己的家目录。

需要让安装器生成硬件配置时，追加：

```bash
  --generate-hardware-config nixos-generate-config ./hosts/vps-pi/hardware-configuration.nix
```

生成后审查并提交 `hosts/vps-pi/hardware-configuration.nix`。其他参数（私钥、端口）见 `nix run .#install -- --help`。

安装过程：kexec 进入临时系统 → disko 格式化并挂载 ext4 根分区到 `/mnt` → 复制系统 → 把 `work/vps-pi/extra-files` 复制到 `/mnt`，主机密钥落到 `/mnt/etc/ssh/`、age 私钥落到 `/mnt/home/tau/.config/sops/age/` → `nixos-install` → 重启。首次开机时 age 私钥已经在磁盘上，sops-nix 可以直接解密。

安装完成后用 `ssh tau@YOUR_PI_SERVER` 登录；root SSH 和密码登录关闭。把该主机 `extra-files` 中的主机私钥移到安全的地方备份；重装同一台服务器时恢复它以保持主机指纹，并恢复 age 私钥以保留解密能力。其他主机必须使用各自的 SSH 主机私钥。

`--build-on local` 在本机构建系统，但默认的 kexec 镜像仍可能由目标机从 GitHub 下载；它不会改变 kexec 的下载位置。国内网络下在 LiveCD 本机安装见[代理说明](proxy.md#livecd-临时使用)。

### 目标机无法从 GitHub 下载 kexec

在能访问 GitHub 的本机下载镜像，再通过 `--kexec` 传入本地文件路径。安装器会通过 SSH 上传该文件，目标机无需访问 GitHub 下载 kexec。以下命令适用于本仓库的两台 x86_64 VPS，以 `vps-pi` 为例，在仓库根目录执行：

```bash
mkdir -p work
curl --fail --location --retry 3 \
  --output work/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz \
  https://github.com/nix-community/nixos-images/releases/download/nixos-25.05/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz
```

确认已完成上面的密钥准备，并核对目标磁盘后，使用本地镜像安装（会清空目标磁盘）：

```bash
nix run .#install -- --flake .#vps-pi --target-host root@YOUR_PI_SERVER \
  --kexec "$PWD/work/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz" \
  --extra-files "$PWD/work/vps-pi/extra-files" --chown /home/tau 1000:100 \
  --build-on local
```

`--kexec` 后必须是已下载的本地文件路径；直接传 GitHub URL 仍可能让目标机下载。本仓库当前的 `nixos-anywhere 1.13.0` 默认使用 `nixos-25.05` 安装镜像，它只负责启动临时安装环境，最终系统版本由 flake 决定。安装 `vps-dev` 时可复用此公开的 x86_64 镜像，但必须改用 `.#vps-dev`、开发机地址及 `work/vps-dev/extra-files`。Oracle ARM 应将镜像文件名中的 `x86_64` 换成 `aarch64`，安装目标换成 `.#oracle-arm`，安装文件改为 `work/oracle-arm/extra-files`；从 x86_64 本机安装 ARM 时仍按下节选择构建位置。

如果目标机连 Nix 二进制缓存也无法访问，在 `--build-on local` 的命令中追加 `--no-substitute-on-destination`，使 disko 和系统闭包由本机通过 SSH 传送。本机仍需能获取这些构建依赖。

## vps-dev 开发服务器

`vps-dev` 为 `x86_64-linux`，使用独立的 `hosts/vps-dev/hardware-configuration.nix` 和 `hosts/vps-dev/disko-fs.nix`，目标磁盘为 `/dev/sda`。安装前在目标机运行 `lsblk` 核对设备，不能套用 `vps-pi` 的 `/dev/vda`。

它与 `vps-pi` 共用 server/base 底座、maintenance、Home Manager 和 Xray 客户端。`hosts/vps-dev/home.nix` 导入原 VPS 的全部现有 home 模块，保留 GCC、GNU Make、uv、Git、Neovim、tmux、Node.js/npm，并额外导入 `home/cli/development.nix` 提供 Python 3、pkg-config、GDB。开发机不导入 pi-web、Podman、Nginx、ACME 或应用 secrets，无需准备 `secrets/server.env` 或 Ignis 凭据。

先按[准备](#准备)以 `install_host=vps-dev` 生成独立主机密钥并复制 age admin key，再安装（会清空 `/dev/sda`）：

```bash
nix run .#install -- --flake .#vps-dev --target-host root@YOUR_DEV_SERVER \
  --extra-files "$PWD/work/vps-dev/extra-files" --chown /home/tau 1000:100 \
  --build-on local
```

若需生成硬件配置，追加 `--generate-hardware-config nixos-generate-config ./hosts/vps-dev/hardware-configuration.nix` 并审查生成文件。目标无法访问 GitHub 时，使用[本地 kexec 镜像](#目标机无法从-github-下载-kexec)。安装后以 `ssh tau@YOUR_DEV_SERVER` 登录；更新命令见[日常更新](#日常更新)。

## Oracle Cloud Ampere ARM

Oracle ARM 启用基础系统、系统 CLI 工具、SSH/SOPS、Xray Reality 服务端和 Podman Ignis；Home Manager 与通用维护模块暂未导入。`modules/nixos/base/cli.nix` 直接提供 Git、Neovim（含 `vi` / `vim` 命令）、tmux、curl、wget、rsync、jq、ripgrep、fd、file、tree、less、zip/unzip、htop、lsof、DNS 工具和 sops/age，重建后即可在普通用户与 root 的系统环境中使用。Xray 使用 `nixpkgs-unstable`。Ignis 使用 `docker.io/nobbe/ignis:latest`，不锁定镜像 digest，并在每次容器启动时拉取该标签的最新镜像（`pull = "always"`）；上游发布新版后，在服务器执行 `sudo systemctl restart podman-ignis.service` 即可更新。持久数据位于 `/home/tau/ignis/`：`vaults/` 保存笔记库，`data/` 保存插件管理与同步等状态，`obsidian-app/` 保存应用缓存；镜像和容器可写层仍位于 `/var/lib/containers/storage`。Nginx 在 `ob.nullcode.cc` 终止 TLS、启用 Basic Auth 和 WebSocket 代理。认证哈希保存在 `secrets/ignis.htpasswd` 的 SOPS 密文中，不要把明文密码写进 Nix 配置。

部署前确认 `ob.nullcode.cc` 的 DNS 指向实例公网地址，并在 OCI 网络安全列表/NSG 放行 TCP 80、443；Xray 的 TCP 2333 也需按客户端访问范围开放。ACME 首次签发证书需要公网可达的 80/443。更换 Ignis 密码时，在本机安全终端交互生成 bcrypt 哈希并直接加密写入 SOPS 文件：

```bash
nix shell nixpkgs#apacheHttpd nixpkgs#sops -c bash -c \
  'htpasswd -nB -C 12 admin | sops encrypt --input-type binary --output-type binary --filename-override secrets/ignis.htpasswd --output secrets/ignis.htpasswd /dev/stdin'
```

Oracle ARM 主机入口是 `.#oracle-arm`，目标平台为 `aarch64-linux`。默认磁盘写为 `/dev/sda`，但 OCI 实例的设备名可能因镜像和实例类型不同而变化；安装前在临时系统中执行 `lsblk`，再修改 [hosts/oracle-arm/disko-fs.nix](/home/tau/.config/flake/hosts/oracle-arm/disko-fs.nix:5)。

从 x86_64 工作站安装时，先按准备步骤以 `install_host=oracle-arm` 准备独立主机密钥和 age 文件，再优先让目标机自己构建 ARM 系统：

```bash
nix run .#install -- --flake .#oracle-arm --target-host root@YOUR_ORACLE_IP \
  --extra-files "$PWD/work/oracle-arm/extra-files" --chown /home/tau 1000:100 \
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

然后执行上面的 `nixos-rebuild test` / `switch`，再运行 `sudo systemctl start podman-ignis.service`，检查原笔记库、插件和同步状态。旧目录保留用于回退；首次安装会自动创建新的空目录，无需复制。

## 旧布局迁移到 ext4 根分区

旧版使用根 tmpfs、独立的 `/nix` 和 `/nix/persist` 保存状态。当前本机仍是此布局：`lsblk` 显示 `/dev/vda` 为 60 GiB，`findmnt /` 显示 tmpfs，磁盘上的 ext4 分区挂在 `/nix`；不能据此认为新版 ext4 `/` 已经部署。

**从旧布局迁移到新版布局必须备份重装，普通 `nixos-rebuild test` / `switch` 无法原地转换。** 在执行首次安装命令前：

1. 将 `/home/tau`、`/etc/ssh`、`/nix/persist/home/tau/.config/sops/age/keys.txt` 及其他所需持久状态备份到目标磁盘之外；若 age 私钥实际位于 `/home/tau/.config/sops/age/keys.txt`，也要备份该文件。保留应用数据和必要的 `/var/lib` 状态。
2. 把同一台服务器的原 SSH 主机密钥和 age 私钥恢复到它自己的 `work/<主机>/extra-files/etc/ssh/` 与 `work/<主机>/extra-files/home/tau/.config/sops/age/`。由原 VPS 迁移到 `vps-pi` 时保留原机身份；新 `vps-dev` 必须使用新生成的 SSH 主机密钥。
3. 核对目标设备并执行对应主机的首次安装命令。disko 会格式化目标整盘，安装完成后恢复用户数据到 `/home/tau`，再验证 SSH、SOPS 和该主机的服务。

主机配置由 `vps` 改名为 `vps-pi` 本身无需擦盘；仓库改名和修改 flake 输出不会立即改变正在运行的 hostname，需重建并激活才生效。上述备份重装是当前旧文件系统布局迁移的要求。

## pi-web 切换到 Podman

`vps-pi` 的 pi-web 由 `podman-pi-web.service` 管理，镜像与持久化说明见[可选服务](services.md)。环境文件已经加密保存为 `secrets/server.env`，由 SOPS 在运行时解密到 `/run/secrets/pi-web.env`，Podman 启动时读取；服务器只需准备现有的 age 私钥，无需另外复制明文 `server.env`。后续使用 `sops edit secrets/server.env` 修改，保留 `PI_WEB_PASSWORD` 等变量，并使用不带 `export` 或值两侧引号的 `KEY=value` 格式。

以下服务切换步骤适用于已采用 ext4 根布局的 `vps-pi`；若仍是根 tmpfs，先完成[旧布局迁移](#旧布局迁移到-ext4-根分区)。已运行旧版 npm 用户服务的机器，在 `vps-pi` 上以 `tau` 停止旧服务，释放 30141 端口：

```bash
systemctl --user disable --now pi-web.service
```

随后按下方的日常更新命令重建 `vps-pi`。Home Manager 会移除旧用户服务，NixOS 会启用 Podman 容器。检查新服务及 HTTPS 访问：

```bash
sudo systemctl status podman-pi-web.service
sudo journalctl -u podman-pi-web.service -n 100 --no-pager
curl -I https://pi.nullcode.cc
```

工作区 `/home/tau/pi-workspace` 由系统自动创建，容器只挂载这个目录，agent 配置、会话和项目分别保存在其中。旧的 `~/.pi`、skills 和项目保留在原处；需要复用时，应选择性复制普通文件到工作区，并避免依赖工作区外路径或指向 `/nix/store` 的符号链接。旧会话记录包含绝对工作路径，不会因复制会话文件而自动改成新路径；模型凭据也可在 Web 的 Models 面板重新配置。宿主机旧的 npm 安装可另行保留或卸载，容器不依赖它。

## 日常更新

以下命令适用于已经采用仓库 ext4 根布局的主机。若 `findmnt /` 显示 tmpfs，先按[旧布局迁移](#旧布局迁移到-ext4-根分区)备份重装。

```bash
nix develop
nixos-rebuild test --flake .#vps-pi --target-host tau@YOUR_PI_SERVER --sudo
# 验证第二个 SSH 会话与网络后保存为启动默认配置
nixos-rebuild switch --flake .#vps-pi --target-host tau@YOUR_PI_SERVER --sudo
```

开发机独立更新，注意使用对应的 flake 输出和目标地址：

```bash
nixos-rebuild test --flake .#vps-dev --target-host tau@YOUR_DEV_SERVER --sudo
nixos-rebuild switch --flake .#vps-dev --target-host tau@YOUR_DEV_SERVER --sudo
```

`test` 临时激活，`switch` 同时更新启动默认项，`boot` 仅更新下次启动。重建只推送新系统，`secrets/` 都是密文，服务器用已有的 age 私钥解密，不需要再上传安装用的 `extra-files`。配置改名和新的 hostname 需要重建并激活才生效，仅修改仓库不会重命名运行中的主机。

私钥与端口可写在本机 SSH 配置：

```sshconfig
Host vps-pi
  HostName YOUR_PI_SERVER
  User tau
  Port 22
  IdentityFile ~/.ssh/id_ed25519

Host vps-dev
  HostName YOUR_DEV_SERVER
  User tau
  Port 22
  IdentityFile ~/.ssh/id_ed25519
```

重建使用对应的 `--target-host vps-pi` 或 `--target-host vps-dev`。修改网络、公钥、端口时先 `test`，保留服务商控制台并检查新会话。失去连接时，可通过控制台重启回到上次 `switch` 的配置。
