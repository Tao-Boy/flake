# 配置结构与基本语法

## 读配置的顺序

1. `flake.nix`：声明依赖，并把输出委托给 `outputs/default.nix`。
2. `outputs/default.nix`：在 `hosts` 表中登记主机名和架构，自动生成 `nixosConfigurations` 与对应架构的 `checks`，并提供开发环境和格式化器。
3. `hosts/<name>/default.nix`：导入共用服务器底座，再显式选择这台机器的硬件、额外基础功能和服务。
4. `hosts/<name>/disko-fs.nix`：导入共用磁盘布局，声明目标磁盘和 BIOS / UEFI 等主机差异。
5. `hosts/<name>/home.nix`：选择用户软件，具体设置在 `home/`。

主机目录只保存主机差异；可复用的功能放在 `modules/nixos/{base,server}`。`modules/nixos/server/default.nix` 显式组合用户、Nix、网络、安全、SOPS 与 SSH，并将默认时区设为 UTC；maintenance 和 Home Manager 由需要的主机单独选择。模块通过 `imports` 明确导入，不自动扫描目录。

| 文件 | 内容 |
| --- | --- |
| `hosts/vps/` | x86_64 VPS 主机 |
| `hosts/oracle-arm/` | Oracle Cloud Ampere aarch64 主机 |
| `modules/nixos/server/default.nix` | 组合服务器共用底座、默认 UTC 时区 |
| `modules/nixos/base/disko.nix` | GPT、EFI `/boot`、ext4 `/`、共用 GRUB 和日志上限 |
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
| `modules/nixos/server/nginx.nix` | 共用 Nginx 推荐参数、防火墙和 ACME 设置 |
| `modules/nixos/server/podman.nix` | 共用 Podman 后端、`/var/lib/containers/storage` 镜像与可写层存储 |
| `modules/nixos/server/pi-web.nix` | Podman pi-web、pi-workspace 挂载、SOPS 环境文件与 HTTPS 代理 |
| `modules/nixos/server/ignis.nix` | Ignis 容器、`~/ignis` 笔记与插件目录、HTTPS 代理和认证 |
| `hosts/vps/disko-fs.nix` | VPS 目标磁盘、BIOS boot 分区和串口参数 |
| `hosts/oracle-arm/disko-fs.nix` | Oracle ARM 目标磁盘和 UEFI 启动设置 |

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

例如，在 `hosts/vps/default.nix` 或 `hosts/oracle-arm/default.nix` 添加 `time.timeZone = "Asia/Shanghai";` 可以覆盖共用底座的 UTC 默认值；在 VPS 的 `home.nix` 中删掉 `../../home/programs/tmux.nix` 一行就不再安装 tmux。软件源中，`pkgs` 是稳定版，`pkgsUnstable` 是单独锁定的 unstable 版。

`system.stateVersion` 和 `home.stateVersion` 表示首次安装时的兼容版本，升级软件时保持原值。

继续学习可参考[Nix 语言基础](https://nix.dev/tutorials/nix-language)和[NixOS 模块](https://nix.dev/tutorials/module-system/module-system)。
