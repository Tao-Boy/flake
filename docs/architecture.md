# 配置结构与基本语法

## 读配置的顺序

1. `flake.nix`：声明依赖，并把输出委托给 `outputs/default.nix`。
2. `outputs/default.nix`：声明 `nixosConfigurations.vps` 和 `nixosConfigurations.oracle-arm`，并按系统架构提供检查、开发环境和格式化器。
3. `hosts/<name>/default.nix`：列出这台机器使用的全部硬件、基础和服务模块。
4. `hosts/<name>/disko-fs.nix`：声明目标磁盘、`/boot` 和 ext4 根文件系统。
5. `hosts/<name>/home.nix`：选择用户软件，具体设置在 `home/`。

主机目录只保存主机差异；可复用的功能放在 `modules/nixos/{base,server}`。这与目标仓库按主机、平台和功能拆分的组织方式一致，同时保留本项目显式列出 imports 的简单入口。

| 文件 | 内容 |
| --- | --- |
| `hosts/vps/` | x86_64 VPS 主机 |
| `hosts/oracle-arm/` | Oracle Cloud Ampere aarch64 主机 |
| `modules/nixos/base/users.nix` | 用户 `tau`、SSH 公钥、sudo |
| `modules/nixos/base/core.nix` | Nix 设置、每周清理旧版本 |
| `modules/nixos/base/networking.nix` | DHCP 网络、BBR 拥塞控制 |
| `modules/nixos/base/security.nix` | nftables 防火墙、内核网络与安全参数 |
| `modules/nixos/base/maintenance.nix` | 时间同步、fstrim、zram |
| `modules/nixos/base/home-manager.nix` | 接入 Home Manager |
| `modules/nixos/server/sops.nix` | 接入 sops-nix 和 age 密钥 |
| `modules/nixos/server/ssh.nix` | SSH、加密的用户 SSH 私钥、fail2ban |
| `modules/nixos/server/xray-client.nix` | Xray 客户端、sops 配置和 `proxy-on` / `proxy-off` |
| `modules/nixos/server/xray-server.nix` | Xray Reality 服务端与 TCP 2333 |
| `modules/nixos/server/nginx.nix` | Nginx 反向代理 pi-web、ACME 证书 |
| `hosts/vps/disko-fs.nix` | GPT、EFI `/boot`、ext4 `/`、GRUB |
| `hosts/oracle-arm/disko-fs.nix` | Oracle ARM 的 EFI `/boot`、ext4 `/`、GRUB |

外部项目的模块（disko、sops-nix、Home Manager）在实际使用它的文件里通过 `inputs.xxx.nixosModules.xxx` 导入。

## 看懂常见写法

| 写法 | 含义 |
| --- | --- |
| `{ enable = true; }` | 属性集合；每项以分号结尾 |
| `[ ./base.nix ./ssh.nix ]` | 列表；元素用空格或换行分隔 |
| `services.openssh.enable = true;` | 等同于 `services = { openssh = { enable = true; }; };` |
| `{ config, lib, ... }: { ... }` | 模块写成函数时，可以使用 NixOS 提供的参数 |
| `imports = [ ./base.nix ];` | 把其他模块加入当前配置 |
| `let http = "..."; in { ... }` | 定义局部变量，在后面用 `${http}` 引用 |
| `inherit inputs;` | 等同于 `inputs = inputs;` |
| `lib.mkIf cond { ... }` | 条件成立时才加入设置 |

例如，在 `hosts/vps/default.nix` 或 `hosts/oracle-arm/default.nix` 把 `time.timeZone = "UTC";` 改为 `"Asia/Shanghai"`；在相应主机的 `home.nix` 中删掉 `../../home/programs/tmux.nix` 一行就不再安装 tmux。软件源中，`pkgs` 是稳定版，`pkgsUnstable` 是单独锁定的 unstable 版。

`system.stateVersion` 和 `home.stateVersion` 表示首次安装时的兼容版本，升级软件时保持原值。

继续学习可参考[Nix 语言基础](https://nix.dev/tutorials/nix-language)和[NixOS 模块](https://nix.dev/tutorials/module-system/module-system)。
