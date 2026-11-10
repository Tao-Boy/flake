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
    home.nix                用户模块选择
modules/nixos/
  base/                    通用 NixOS 模块
  server/                  服务器功能模块
home/                     Home Manager 用户模块
secrets/                  加密的 Xray 配置与统一 SSH 私钥
.sops.yaml                加密所用的 age 公钥
```

从 `flake.nix` 进入 `outputs/default.nix`，再沿着 `hosts/<name>/default.nix` 的 `imports` 打开配置即可读完整份系统。主机相关内容放在 `hosts/<name>`，可复用的系统功能放在 `modules/nixos`，用户软件放在 `home/`。当前主机入口是 `vps`（x86_64）和 `oracle-arm`（aarch64）。

| 想修改什么 | 修改位置 |
| --- | --- |
| SSH 公钥、用户名 | `modules/nixos/base/users.nix` |
| SSH 私钥（SOPS 密文） | `secrets/id_ed25519`，更新方式见[安装说明](docs/deployment.md#准备) |
| 主机名、时区、启用哪些功能 | `hosts/<name>/default.nix` |
| 安装哪些用户软件 | `hosts/<name>/home.nix` |
| 软件的具体设置 | `home/` |
| 目标磁盘和文件系统 | `hosts/<name>/disko-fs.nix` |
| Xray 客户端和代理开关 | `modules/nixos/server/xray-client.nix` |
| Xray Reality 服务端 | `modules/nixos/server/xray-server.nix` |
| Xray 客户端配置 | `sops edit secrets/client.json` |
| Xray 服务端配置 | `sops edit secrets/server.json` |
| 依赖版本 | `nix flake update`，结果写入 `flake.lock` |

## 文件系统

安装布局是同一块磁盘上的 GPT、EFI `/boot` 分区和占满剩余空间的 ext4 `/` 分区。根目录直接使用硬盘，`/nix`、`/home`、`/var` 和日志都在这个 ext4 文件系统中持久保存；没有根 tmpfs，也没有 `/nix/persist` 或 impermanence 清单。

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

`.#vps` 和 `.#oracle-arm` 分别选择 x86_64 客户端 VPS 与 aarch64 Oracle 服务端。Oracle 服务端的 Xray 随系统启动；VPS 客户端需要在服务器上用 `proxy-on` / `proxy-off` 开关。

CI 默认构建当前 x86_64 检查；ARM 主机的系统和 disko 脚本可在 ARM builder 上用 `--system aarch64-linux` 验证。

- [配置结构与基本语法](docs/architecture.md)
- [定制配置与新增机器](docs/customization.md)
- [安装与远程更新](docs/deployment.md)
- [用户软件与软件源](docs/home-manager.md)
- [可选服务](docs/services.md)
- [Xray、加密凭据与 LiveCD](docs/proxy.md)
- [检查、回滚与备份](docs/operations.md)
