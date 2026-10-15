# 配置结构与基本语法

## 读配置的顺序

1. `flake.nix`：`nixosConfigurations.vps` 指向 `machines/vps/`。
2. `machines/vps/default.nix`：`imports` 列出这台机器用到的全部模块，每行注释说明用途；下面几行设置主机名、时区等。
3. 按 `imports` 依次打开 `user.nix` 和 `modules/` 中的文件。每个模块都是普通的 NixOS 设置，可以在 [NixOS 选项搜索](https://search.nixos.org/options) 中查到含义。
4. `machines/vps/home.nix`：选择用户软件，具体设置在 `home/`。

| 文件 | 内容 |
| --- | --- |
| `user.nix` | 唯一的用户 `tau`、SSH 公钥、sudo |
| `modules/base.nix` | Nix 设置、每周清理旧版本 |
| `modules/networking.nix` | DHCP 网络、BBR 拥塞控制 |
| `modules/sops.nix` | 接入 sops-nix，用服务器上的 age 私钥（及 SSH 主机密钥）解密 |
| `modules/ssh.nix` | SSH 只允许公钥登录、fail2ban |
| `modules/hardening.nix` | nftables 防火墙、内核网络与安全参数 |
| `modules/maintenance.nix` | 时间同步、fstrim、zram |
| `modules/proxy.nix` | Xray 与 `proxy-on` / `proxy-off` |
| `modules/home-manager.nix` | 接入 Home Manager |
| `modules/file-system.nix` | 磁盘分区、tmpfs 根目录、GRUB |
| `modules/impermanence.nix` | 重启后保留的目录和文件 |
| `modules/nginx.nix` | Nginx 反向代理 pi-web、ACME 证书（vps 已启用） |
| `modules/docker.nix` | 可选：Docker 与 OCI 容器，默认未启用 |

外部项目的模块（disko、impermanence、sops-nix、Home Manager）在用到它的文件里通过 `inputs.xxx.nixosModules.xxx` 导入。

## 看懂常见写法

| 写法 | 含义 |
| --- | --- |
| `{ enable = true; }` | 属性集合；每项以分号结尾 |
| `[ ./base.nix ./ssh.nix ]` | 列表；元素用空格或换行分隔 |
| `services.openssh.enable = true;` | 等同于 `services = { openssh = { enable = true; }; };` |
| `{ config, lib, ... }: { ... }` | 模块写成函数时，可以使用 NixOS 提供的 `config`、`lib`、`pkgs`、`inputs` 等参数；不需要时直接写 `{ ... }` |
| `imports = [ ./base.nix ];` | 把其他模块加入当前配置 |
| `let http = "..."; in { ... }` | 定义局部变量，在后面用 `${http}` 引用 |
| `"http://127.0.0.1:${toString port}"` | 字符串中插入变量 |
| `inherit inputs;` | 等同于 `inputs = inputs;` |
| `config.sops.secrets."xray.json".path` | 读取配置中其他选项的值 |
| `lib.mkIf cond { ... }` | 条件成立时才加入这些设置 |
| `lib.mkForce value` | 强制覆盖别处设置的值，例如取消 Xray 开机自启 |

例如，在 `machines/vps/default.nix` 把 `time.timeZone = "UTC";` 改为 `"Asia/Shanghai"`；在 `machines/vps/home.nix` 删掉 `../../home/programs/tmux.nix` 一行就不再安装 tmux。软件源中，`pkgs` 是稳定版，`pkgsUnstable` 是单独锁定的 unstable 版。

`system.stateVersion` 和 `home.stateVersion` 表示首次安装时的兼容版本，升级软件时保持原值。

继续学习可参考 [Nix 语言基础](https://nix.dev/tutorials/nix-language) 和 [NixOS 模块](https://nix.dev/tutorials/module-system/module-system)。
