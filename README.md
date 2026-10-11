# flake

面向 x86_64 Linux VPS 的 NixOS 配置，使用锁定的 NixOS 26.05 和 Home Manager。系统中只有一个用户 `tau`，通过 SSH 公钥登录。

## 目录

```text
flake.nix                 入口：依赖、机器列表、工具
user.nix                  唯一的用户与 SSH 公钥
machines/vps/
  default.nix             这台机器启用哪些模块
  home.nix                这台机器安装哪些用户软件
  storage.nix             目标磁盘与分区大小
  hardware-configuration.nix
modules/                  系统模块，每个文件负责一件事
home/                     用户软件与 dotfiles
secrets/                  加密的 Xray 配置与 SSH 主机密钥（自己创建）
.sops.yaml                加密所用的 age 公钥
```

从 `flake.nix` 开始，沿着 `machines/vps/default.nix` 的 `imports` 打开各个模块即可读完整份配置。Nix 基本写法见[结构说明](docs/architecture.md)。

| 想修改什么 | 修改位置 |
| --- | --- |
| SSH 公钥、用户名 | `user.nix` |
| 主机名、时区、启用哪些功能 | `machines/vps/default.nix` |
| 安装哪些用户软件 | `machines/vps/home.nix` |
| 软件的具体设置 | `home/` |
| 目标磁盘、`/home` 大小 | `machines/vps/storage.nix` |
| Xray 节点与路由 | `sops edit secrets/xray.json` |
| 代理端口与开关 | `modules/proxy.nix` |
| 依赖版本 | `nix flake update`，结果写入 `flake.lock` |

## 首次使用

```bash
git clone https://github.com/Tao-Boy/flake.git
cd flake
nix develop
```

安装前准备五项：

1. 在 `user.nix` 填写 `.pub` 文件的完整 SSH 公钥。
2. 核对 `machines/vps/storage.nix` 的目标整盘，默认为 `/dev/vda`。
3. 保留适用的 QEMU 硬件模板，或按[安装说明](docs/deployment.md)让 nixos-anywhere 生成硬件配置。网络默认使用 DHCP / IPv6 RA；服务商要求静态地址时在机器中补充。
4. 按[代理说明](docs/proxy.md)生成 age 密钥、填写 `.sops.yaml`，用 `sops` 创建 `secrets/xray.json` 并填写真实节点。
5. 按[安装说明](docs/deployment.md#ssh-主机密钥)生成 SSH 主机密钥并加密为 `secrets/ssh_host_ed25519_key`。

```bash
git add user.nix machines/vps .sops.yaml secrets/
nix flake check --no-build --no-write-lock-file
```

**首次安装会清空指定磁盘。** 核对磁盘并备份后，按[安装与远程更新](docs/deployment.md)执行完整命令，其中包含 age 私钥部署。

## 日常修改

```bash
nix develop
nix fmt
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 验证网络与第二个 SSH 会话后保存为启动默认配置。
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
```

`.#vps` 选择 `flake.nix` 中的 `nixosConfigurations.vps`。新增 Nix 文件先 `git add`，再检查或重建。默认启用本地 Xray；在服务器上用 `proxy-on` / `proxy-off` 开关代理，重启后恢复开启。

根目录 `/` 使用 tmpfs，重启清空；`/home` 和 `/nix` 是独立的 ext4 分区。SSH 主机密钥与 Xray 配置加密保存在仓库的 `secrets/`，开机时用 `/home/tau/.ssh/age.key` 解密。数据库、ACME 等 `/var` 状态需要额外安排持久存储。

CI 检查 Nix 文件格式，并构建 vps 系统。详细说明：

- [配置结构与基本语法](docs/architecture.md)
- [定制配置与新增机器](docs/customization.md)
- [安装与远程更新](docs/deployment.md)
- [用户软件与软件源](docs/home-manager.md)
- [可选服务](docs/services.md)
- [Xray、加密凭据与 LiveCD](docs/proxy.md)
- [检查、回滚与备份](docs/operations.md)
