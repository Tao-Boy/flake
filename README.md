# flake

面向 x86_64 和 aarch64 Linux 主机的 NixOS 配置，使用锁定的 NixOS 26.05、Home Manager 和 disko。系统中只有一个用户 `tau`，通过 SSH 公钥登录。

## 目录

```text
flake.nix                 依赖入口
outputs/default.nix       NixOS 主机、检查、开发环境和格式化器
hosts/
  vps/
    default.nix             x86_64 VPS 主机入口
    disko-fs.nix            磁盘布局：/boot 加 ext4 根分区
    hardware-configuration.nix
    home.nix                用户模块选择
  oracle-arm/
    default.nix             Oracle Cloud Ampere ARM 主机入口
    disko-fs.nix            EFI /boot 加 ext4 根分区
    hardware-configuration.nix
    home.nix                用户模块选择（Oracle 当前未导入）
modules/nixos/
  base/                    通用 NixOS 模块与共享磁盘布局
  server/                  共用服务器入口及 Xray、Nginx、Ignis 等服务
home/                     Home Manager 用户模块
secrets/                  加密的 Xray、SSH、pi-web 与 Ignis 凭据
.sops.yaml                加密所用的 age 公钥
```

从 `flake.nix` 进入 `outputs/default.nix`，再沿着 `hosts/<name>/default.nix` 的 `imports` 打开配置即可读完整份系统。`outputs/default.nix` 的 `hosts` 表统一登记主机名与架构，自动生成系统入口和对应架构的检查。两台机器通过 `modules/nixos/server/default.nix` 导入共用底座，主机目录保留硬件、磁盘和服务选择；Home Manager 用户软件目前仅由 VPS 导入。Oracle ARM 导入系统底座、基础 CLI 工具、Xray 服务端和 Podman Ignis。

| 想修改什么 | 修改位置 |
| --- | --- |
| SSH 公钥、用户名 | `modules/nixos/base/users.nix` |
| SSH 私钥（SOPS 密文） | `secrets/id_ed25519`，更新方式见[安装说明](docs/deployment.md#准备) |
| 主机名、架构 | `outputs/default.nix` 中的 `hosts` 表，与 `hosts/<name>/` 目录同名 |
| 默认时区、共用系统底座 | `modules/nixos/server/default.nix` |
| 主机时区、启用哪些功能 | `hosts/<name>/default.nix` |
| Oracle ARM 的系统 CLI 工具 | `modules/nixos/base/cli.nix` |
| 安装哪些用户软件 | `hosts/<name>/home.nix`（需启用 Home Manager） |
| 软件的具体设置 | `home/` |
| 目标磁盘、启动差异 | `hosts/<name>/disko-fs.nix` |
| 共用分区布局、GRUB 与日志上限 | `modules/nixos/base/disko.nix` |
| Xray 客户端和代理开关 | `modules/nixos/server/xray-client.nix` |
| Xray Reality 服务端 | `modules/nixos/server/xray-server.nix`（unstable） |
| 共用 Nginx 与 ACME 设置 | `modules/nixos/server/nginx.nix` |
| 共用 Podman 后端与镜像存储路径 | `modules/nixos/server/podman.nix` |
| VPS pi-web 容器与反向代理 | `modules/nixos/server/pi-web.nix` |
| pi-web 环境变量（SOPS 密文） | `sops edit secrets/server.env` |
| Oracle ARM Ignis 与 Nginx | `modules/nixos/server/ignis.nix` |
| Xray 客户端配置 | `sops edit secrets/client.json` |
| Xray 服务端配置 | `sops edit secrets/server.json` |
| 依赖版本 | `nix flake update`，结果写入 `flake.lock` |

## 文件系统

安装布局是同一块磁盘上的 GPT、EFI `/boot` 分区和占满剩余空间的 ext4 `/` 分区。根目录直接使用硬盘，`/nix`、`/home`、`/var` 和日志都在这个 ext4 文件系统中持久保存；没有根 tmpfs，也没有 `/nix/persist` 或 impermanence 清单。

pi-web 与 Ignis 的 Podman 镜像及容器可写层统一存放在 `/var/lib/containers/storage`。pi-web 的工作目录与挂载数据位于 `/home/tau/pi-workspace`；Ignis 的笔记、插件与应用缓存位于 `/home/tau/ignis`。

`vps` 和 `oracle-arm` 共用同一对用户 SSH 密钥：公钥直接写在 `modules/nixos/base/users.nix`，私钥以 SOPS 密文保存在 `secrets/id_ed25519`，激活时解密到 `/run/secrets/id_ed25519`（所有者 `tau`，权限 `0600`），并用于 `tau` 的出站 SSH。根目录的明文 `id_ed25519` 已被 Git 忽略，只用于本机导入。

SOPS 的 age 私钥位于 `/home/tau/.config/sops/age/keys.txt`，SSH 主机密钥位于 `/etc/ssh/`。这两类文件都随根文件系统保留，仍然需要备份。

## 首次使用

```bash
git clone https://github.com/Tao-Boy/flake.git
cd flake
nix develop
```

安装前准备四项：

1. 核对 `modules/nixos/base/users.nix` 中的统一 SSH 公钥；更换密钥时按[安装说明](docs/deployment.md#准备)同时更新加密私钥。
2. 核对目标主机的磁盘文件：VPS 使用 `hosts/vps/disko-fs.nix`（默认 `/dev/vda`），Oracle ARM 使用 `hosts/oracle-arm/disko-fs.nix`（默认 `/dev/sda`）。
3. 保留硬件配置，或按[安装说明](docs/deployment.md)让 nixos-anywhere 生成。
4. 按[安装说明](docs/deployment.md#准备)生成管理密钥和服务器 SSH 主机密钥，再按[代理说明](docs/proxy.md)检查 `secrets/client.json` 和 `secrets/server.json`。

```bash
git add hosts modules outputs .sops.yaml secrets/
nix flake check --no-build --no-write-lock-file
```

**首次安装会清空指定磁盘。** 核对磁盘并备份后，按[安装与远程更新](docs/deployment.md)执行完整命令。

## 日常修改

```bash
nix develop
nix fmt
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 验证网络与第二个 SSH 会话后保存为启动默认配置。
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
```

`.#vps` 和 `.#oracle-arm` 分别选择 x86_64 VPS 与 aarch64 Oracle 服务端。Xray 客户端与服务端均使用 `nixpkgs-unstable`；VPS 客户端需要在服务器上用 `proxy-on` / `proxy-off` 开关。VPS 的 pi-web 使用 `ghcr.io/agegr/pi-web:latest`，由 Podman 运行并通过 `pi.nullcode.cc` 提供 HTTPS，工作目录和数据位于 `/home/tau/pi-workspace`，环境文件由 SOPS 从 `secrets/server.env` 解密提供。Oracle ARM 目前启用 Xray Reality 和 Podman Ignis，Ignis 通过 `ob.nullcode.cc` 的 HTTPS、Nginx Basic Auth 提供访问。

CI 默认构建当前 x86_64 检查；ARM 主机的系统和 disko 脚本可在 ARM builder 上用 `--system aarch64-linux` 验证。

- [配置结构与基本语法](docs/architecture.md)
- [定制配置与新增机器](docs/customization.md)
- [安装与远程更新](docs/deployment.md)
- [用户软件与软件源](docs/home-manager.md)
- [可选服务](docs/services.md)
- [Xray、加密凭据与 LiveCD](docs/proxy.md)
- [检查、回滚与备份](docs/operations.md)
