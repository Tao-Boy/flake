# 结构设计与迁移

## 分层原则

`machines` 是部署对象，`profiles` 是角色组合，`modules` 是可复用功能。机器选择角色并覆盖少量原生选项；角色只组合模块；模块不读取机器名称或整个仓库的机器清单。`lib` 只负责构造 NixOS 系统及接入探测报告，`outputs` 只负责组装 flake 输出。

系统与用户配置分别放在 `modules/nixos` 和 `modules/home`，避免相同名称的选项在不同模块体系中混用。用户配置按工具用途和程序拆分，不再把 Git、编辑器、终端复用器与几十个包混在同一个文件中。

## 参考依据

| 项目 | 借鉴内容 | 本仓库的取舍 |
| --- | --- | --- |
| [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs/blob/main/standard/flake.nix) | 系统模块与 Home Manager 模块分开、标准 flake 输出 | 仅保留当前需要的 Linux 输出，用户环境随 NixOS 激活 |
| [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config/blob/main/flake.nix) | 输入与 outputs 分离、共享配置与机器差异分层 | 小规模机器清单；不引入递归模块加载框架或额外部署工具 |
| [hlissner/dotfiles](https://github.com/hlissner/dotfiles/blob/master/default.nix) | 功能模块和可覆盖的共享默认值 | 显式 imports、原生选项，避免大规模自定义选项体系 |
| [nixos-anywhere](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md) | 安装阶段生成 facter 报告，再构建系统 | 使用 nixpkgs 已包含的 facter 模块，不新增 flake 输入 |

借鉴的是职责划分与上游接口，未复制其他仓库的个人硬件、地址、公钥或秘密。

## 路径迁移

| 原路径 | 新路径 |
| --- | --- |
| `hosts/vps/default.nix` | `machines/vps/default.nix` |
| `hosts/vps/hardware-configuration.nix` | `machines/vps/hardware.nix` + 生成的 `facter.json` |
| `hosts/vps/disk-config.nix` | `machines/vps/storage.nix` + `modules/nixos/storage/ephemeral-root.nix` |
| `home/hosts/vps.nix` | `machines/vps/home.nix` |
| `modules/base/` | `modules/nixos/core/` + `profiles/nixos/base.nix` |
| `modules/nixos/server.nix` | `profiles/nixos/server.nix` + 网络、安全、维护模块 |
| `home/base/` | `modules/home/` + `profiles/home/server.nix` |
| `vars/default.nix` | `users.nix` |
| `scripts/vps.sh` | 删除；`outputs/packages.nix` 直接导出安装器 |
| CI 内临时生成的 VM 测试 | `tests/persistence.nix` |

迁移已有配置时，先将真实公钥和身份信息移到 `users.nix`，将实际磁盘、静态网络和本机用户差异移到对应机器文件。不要用仓库中的空公钥模板覆盖已经工作的管理员凭据。

`nixosConfigurations.vps`、`nix run .#install`、`.#nixos-anywhere`、`.#checks.x86_64-linux.install` 与 `.home` 等原有入口保留。配置布局改名不改变系统主机名。磁盘布局、管理员 UID 1000、SSH 主机密钥持久路径和兼容版本保持原值。

已安装机器首次迁移应从其当前 NixOS 环境生成报告，而不是重新运行擦盘安装器：

```bash
# 在目标机器执行，输出文件是硬件信息，不是磁盘格式化指令
sudo nix run nixpkgs#nixos-facter > facter.json
# 将报告复制回本机 machines/vps/facter.json，审查并 git add
```

随后执行求值、构建、远程 `test` 和 `switch`。硬件报告生成的驱动可能随真实硬件不同；默认 DHCP 从上游生成规则匹配物理以太网，DNS 跟随服务商，因此原先自定义网络参数需要主动迁移。
