# 配置结构

配置分为三部分：`machines/` 负责每台机器的选择，`modules/nixos/` 负责共享系统配置，`home/` 负责全部用户软件和 dotfiles。

| 位置 | 职责 |
| --- | --- |
| `flake.nix`、`flake.lock` | 输入及版本锁定 |
| `outputs.nix` | 系统、安装器、格式化器和开发环境输出 |
| `machines/default.nix` | 机器名称与配置入口 |
| `machines/<name>/default.nix` | 选择系统模块，设置机器差异 |
| `machines/<name>/home.nix` | 选择该机器启用的用户软件模块 |
| `machines/<name>/hardware-configuration.nix` | 用户管理的硬件配置 |
| `machines/<name>/storage.nix` | 选择存储布局，指定目标磁盘 |
| `modules/nixos/` | 共享系统功能 |
| `modules/home-manager.nix` | 接入 Home Manager，加载公共用户设置与软件源 |
| `modules/disko.nix` | 接入 disko |
| `home/` | 用户软件配置与公共 Home Manager 设置 |
| `users.nix` | 管理员身份、公钥 |

`outputs.nix` 根据机器清单构造系统，主机名默认采用清单名称。平台、系统功能与用户配置入口都由机器声明。Home Manager 与 disko 的上游模块在各自接入文件中间接导入。

每台机器独立选择配置：`default.nix` 从 `modules/` 选择基础、网络、安全、服务与接入模块，`home.nix` 从 `home/` 选择 shell、工具和程序。共享目录不根据机器名称判断是否启用功能。

`modules/nixos/base.nix` 集中管理 Nix、账号与基础系统设置，网络、安全和维护服务由机器逐项导入。Home Manager 接入文件通过 `sharedModules` 加载 `home/default.nix` 的公共兼容版本，软件仍由机器选择。QEMU 客户机服务在 VPS 入口启用。

机器需要 Home Manager 时导入 `modules/home-manager.nix`，并将 `home-manager.users.<用户名>` 指向自己的 `home.nix`；不需要时省略这两项。存储布局自行导入 disko 接入文件，机器只选择布局并指定磁盘。

硬件配置按固定路径导入。用户可保留适用的 QEMU 模板，或选择由 nixos-anywhere 生成普通 Nix 文件；后续重建直接使用保存的文件。

配置沿用 NixOS / Home Manager 默认值，仅声明实际需要的差异；账号格式与登录凭据由 NixOS 原生检查验证。CI 直接求值和构建标准输出，仅为选用 disko 的机器构建其脚本。

结构参考 [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)、[ryan4yin/nix-config](https://github.com/ryan4yin/nix-config) 和 [hlissner/dotfiles](https://github.com/hlissner/dotfiles) 的系统与用户配置分离、输入与输出分离、共享功能模块化思路。硬件生成接口沿用 [nixos-anywhere](https://github.com/nix-community/nixos-anywhere/blob/1.13.0/src/nixos-anywhere.sh)。
