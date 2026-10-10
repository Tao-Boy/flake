# 结构设计与迁移

## 职责划分

`machines/` 声明部署对象和本机系统差异，`modules/nixos/` 提供共享系统配置，`home/` 保存 Home Manager 用户配置。共享系统组合入口是 `modules/nixos/default.nix`，共享用户组合入口是 `home/default.nix`，仓库不再增加 `profiles/` 层。

系统模块使用 NixOS 选项，用户模块使用 Home Manager 选项，两者分别维护。`modules/home.nix` 是 NixOS 接入文件：它导入 Home Manager 模块，并将 `home/default.nix` 与机器清单指定的 `home/machines/<name>.nix` 组合为管理员用户环境。用户的软件和 dotfiles 均位于 `home/`。

`lib/nixos-system.nix` 只构造系统、传递输入与机器信息、设置默认平台和主机名。它的模块列表只加载本地机器入口；外部 Home Manager / disko 模块分别由 `modules/home.nix` 和 `modules/disko.nix` 导入。机器通过 `storage.nix` 选择 disko 接入和具体存储布局，保持依赖与配置入口清晰。

| 导入入口 | 下一层配置 |
| --- | --- |
| `outputs/default.nix` | 读取机器清单，以 `lib/nixos-system.nix` 构造系统 |
| `machines/vps/default.nix` | 共享系统、用户接入、硬件文件、存储配置 |
| `modules/nixos/default.nix` | core、networking、security、services |
| `modules/home.nix` | 上游 Home Manager 模块、`home/`、机器用户差异 |
| `machines/vps/storage.nix` | `modules/disko.nix`、共享存储布局 |
| `modules/disko.nix` | 上游 disko 模块 |

硬件文件按固定路径显式导入，不读取 facter 报告或判断文件存在性。仓库中的文件是 QEMU 模板；用户可以保留、手工替换或通过安装器生成实际配置。后续求值与重建直接使用已保存的 Nix 文件。

## 参考依据

| 项目 | 借鉴内容 | 本仓库的取舍 |
| --- | --- | --- |
| [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs/blob/main/standard/flake.nix) | 分离系统与 Home Manager、标准 flake 输出 | 用户环境放在 `home/`，随 NixOS 激活 |
| [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config/blob/main/flake.nix) | 输入与 outputs 分离、共享配置与机器差异分开 | 使用小规模机器清单和显式导入 |
| [hlissner/dotfiles](https://github.com/hlissner/dotfiles/blob/master/default.nix) | 功能模块与可覆盖的默认值 | 保留原生选项，不增加自定义模块框架 |
| [nixos-anywhere](https://github.com/nix-community/nixos-anywhere/blob/1.13.0/src/nixos-anywhere.sh) | 用户显式选择硬件配置生成后端 | 使用 `nixos-generate-config` 生成普通 Nix 文件 |

这些参考用于职责划分与接口设计，个人硬件、地址、公钥和秘密不纳入共享配置。

## 路径迁移

| 原路径 | 当前路径 |
| --- | --- |
| `hosts/vps/default.nix` | `machines/vps/default.nix` |
| `hosts/vps/hardware-configuration.nix`、`machines/vps/hardware.nix` | `machines/vps/hardware-configuration.nix` |
| `hosts/vps/disk-config.nix` | `machines/vps/storage.nix` + `modules/nixos/storage/ephemeral-root.nix` |
| `home/hosts/vps.nix`、`machines/vps/home.nix` | `home/machines/vps.nix` |
| `profiles/nixos/` | `modules/nixos/default.nix` |
| `profiles/home/server.nix` | `home/default.nix` |
| `home/base/`、`modules/home/` | `home/shell/`、`home/cli/`、`home/programs/` |
| 系统构造器中的 Home Manager 设置 | `modules/home.nix` |
| `lib/hardware-report.nix`、facter 测试报告 | 删除 |
| `vars/default.nix` | `users.nix` |
| `scripts/vps.sh` | 删除；`outputs/packages.nix` 直接导出安装器 |
| CI 中的 VM 测试 | `tests/persistence.nix` |

迁移已有配置时，保留真实管理员身份、公钥、磁盘和静态网络差异。已有硬件配置可直接迁入标准文件；也可在目标 NixOS 中执行以下命令生成新文件，再复制到本机并审查：

```bash
sudo nixos-generate-config --show-hardware-config --no-filesystems > hardware-configuration.nix
# 复制回本机 machines/vps/hardware-configuration.nix，审查并 git add
```

`--no-filesystems` 避免重复声明由 disko 管理的挂载点。已安装机器使用 `nixos-rebuild test` / `switch`，无需再次运行擦盘安装器。

`nixosConfigurations.vps`、`nix run .#install`、`.#nixos-anywhere`、`.#checks.x86_64-linux.install` 与 `.home` 等入口保留。主机名、磁盘布局、管理员 UID 1000、SSH 主机密钥持久路径和兼容版本保持原值。
