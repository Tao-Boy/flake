# 配置结构

配置分为三部分：`machines/` 负责每台机器的选择，`modules/nixos/` 负责共享系统配置，`home/` 负责全部用户软件和 dotfiles。

| 位置 | 职责 |
| --- | --- |
| `flake.nix`、`flake.lock` | 输入及版本锁定 |
| `outputs/default.nix` | 系统、安装器、格式化器和开发环境输出 |
| `machines/default.nix` | 机器名称、平台、系统入口和用户模块选择入口 |
| `machines/<name>/default.nix` | 选择系统模块，设置机器差异 |
| `machines/<name>/home.nix` | 选择该机器启用的用户软件模块 |
| `machines/<name>/hardware-configuration.nix` | 用户管理的硬件配置 |
| `machines/<name>/storage.nix` | 选择存储布局，指定目标磁盘 |
| `modules/nixos/` | 共享系统功能 |
| `modules/home-manager.nix` | 接入 Home Manager，加载机器指定的用户配置 |
| `modules/disko.nix` | 接入 disko |
| `home/` | 用户软件配置与公共 Home Manager 设置 |
| `users.nix` | 管理员身份、公钥 |

`outputs/default.nix` 根据机器清单构造系统，只加载本地机器入口。Home Manager 与 disko 的上游模块在各自接入文件中间接导入。

每台机器独立选择配置：`default.nix` 从 `modules/` 选择系统核心、网络、安全、服务与接入模块，`home.nix` 从 `home/` 选择公共设置、shell、工具和程序。共享目录不根据机器名称判断是否启用功能。

`modules/nixos/core/default.nix` 只组合 Nix、账号与基础系统设置，网络、安全和维护服务由机器逐项导入。`home/default.nix` 只声明公共兼容版本，同样由机器显式选择。Home Manager 接入文件不会额外导入用户软件。

机器需要 Home Manager 时导入 `modules/home-manager.nix`，并在清单中指定 `home` 入口；不需要时，两者均可省略。disko 由机器的存储配置选择，CI 仅在对应构建输出存在时构建其脚本。

硬件配置按固定路径导入。用户可保留适用的 QEMU 模板，或选择由 nixos-anywhere 生成普通 Nix 文件；后续重建直接使用保存的文件。

仓库使用标准 NixOS / Home Manager 选项与显式 imports，不维护 `profiles/`、`tests/`、自定义检查输出或安装包装脚本。CI 直接求值和构建标准输出。

结构参考 [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)、[ryan4yin/nix-config](https://github.com/ryan4yin/nix-config) 和 [hlissner/dotfiles](https://github.com/hlissner/dotfiles) 的系统与用户配置分离、输入与输出分离、共享功能模块化思路。硬件生成接口沿用 [nixos-anywhere](https://github.com/nix-community/nixos-anywhere/blob/1.13.0/src/nixos-anywhere.sh)。
