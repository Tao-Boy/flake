# flake

面向 x86_64 Linux VPS 的 NixOS 配置，使用锁定的 NixOS 26.05 和 Home Manager。系统中只有一个用户 `tau`，通过 SSH 公钥登录。

## 目录

```text
flake.nix                 入口：依赖、机器列表、工具
user.nix                  唯一的用户与 SSH 公钥
machines/vps/
  default.nix             这台机器启用哪些模块
  home.nix                这台机器安装哪些用户软件
  storage.nix             目标磁盘
  hardware-configuration.nix
modules/                  系统模块，每个文件负责一件事
home/                     用户软件与 dotfiles
secrets/                  加密的 Xray 配置与 SSH 私钥（自己创建）
.sops.yaml                加密所用的 age 公钥（管理密钥）
```

从 `flake.nix` 开始，沿着 `machines/vps/default.nix` 的 `imports` 打开各个模块即可读完整份配置。Nix 基本写法见[结构说明](docs/architecture.md)。

| 想修改什么 | 修改位置 |
| --- | --- |
| SSH 公钥、用户名 | `user.nix` |
| 主机名、时区、启用哪些功能 | `machines/vps/default.nix` |
| 安装哪些用户软件 | `machines/vps/home.nix` |
| 软件的具体设置 | `home/` |
| 目标磁盘 | `machines/vps/storage.nix` |
| 重启后保留哪些文件 | `modules/impermanence.nix` |
| Xray 节点与路由 | `sops edit secrets/xray.json` |
| 代理端口与开关 | `modules/proxy.nix` |
| 依赖版本 | `nix flake update`，结果写入 `flake.lock` |

## 首次使用

```bash
git clone https://github.com/Tao-Boy/flake.git
cd flake
nix develop
```

安装前准备四项：

1. 在 `user.nix` 填写 `.pub` 文件的完整 SSH 公钥。
2. 核对 `machines/vps/storage.nix` 的目标整盘，默认为 `/dev/vda`。
3. 保留硬件配置，或按[安装说明](docs/deployment.md)让 nixos-anywhere 生成。网络默认使用 DHCP / IPv6 RA；服务商要求静态地址时在机器中补充。
4. 按[安装说明](docs/deployment.md#准备)生成管理密钥（填写 `.sops.yaml`）和服务器 SSH 主机密钥，再按[代理说明](docs/proxy.md)创建 `secrets/xray.json`。

```bash
git add user.nix machines/vps .sops.yaml secrets/
nix flake check --no-build --no-write-lock-file
```

**首次安装会清空指定磁盘。** 核对磁盘并备份后，按[安装与远程更新](docs/deployment.md)执行完整命令，其中包含主机密钥与 age 私钥的部署。

## 日常修改

```bash
nix develop
nix fmt
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 验证网络与第二个 SSH 会话后保存为启动默认配置。
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
```

`.#vps` 选择 `flake.nix` 中的 `nixosConfigurations.vps`。新增 Nix 文件先 `git add`，再检查或重建。Xray 开机不自动启动，在服务器上用 `proxy-on` / `proxy-off` 开关。

根目录 `/` 使用 tmpfs，重启清空；磁盘上只有 `/boot` 和 `/nix` 两个分区。需要保留的文件（家目录 `/home/tau`、日志、machine-id、SSH 主机密钥等）由 [impermanence](https://github.com/nix-community/impermanence) 保存在 `/nix/persist`，清单见 `modules/impermanence.nix`。Xray 配置加密保存在 `secrets/`，开机时由 sops-nix 用服务器上的 age 私钥 `/nix/persist/home/tau/.config/sops/age/keys.txt` 解密，见[两把密钥](docs/deployment.md#两把密钥)；主机私钥和管理密钥都由你自己保存和备份，不进入仓库。

CI 检查 Nix 文件格式，并构建 vps 系统。详细说明：

- [配置结构与基本语法](docs/architecture.md)
- [定制配置与新增机器](docs/customization.md)
- [安装与远程更新](docs/deployment.md)
- [用户软件与软件源](docs/home-manager.md)
- [可选服务](docs/services.md)
- [Xray、加密凭据与 LiveCD](docs/proxy.md)
- [检查、回滚与备份](docs/operations.md)
