# 用户软件配置

所有用户软件和 dotfiles 均放在 `home/`，由 Home Manager 随 NixOS 重建激活。机器在自己的 `home.nix` 中逐项选择，例如：

```nix
# machines/vps/home.nix
{
  imports = [
    ../../home
    ../../home/shell
    ../../home/cli/utilities.nix
    ../../home/programs/git.nix
  ];
}
```

这是精简选择示例；实际 VPS 还选择诊断、网络工具、Neovim 和 tmux。`../../home` 只提供公共兼容版本，不会自动启用软件。

| 内容 | 位置 |
| --- | --- |
| 公共兼容版本 | `home/default.nix` |
| Bash、fzf、bat、eza | `home/shell/default.nix` |
| 文件、下载、归档工具 | `home/cli/utilities.nix` |
| 进程、磁盘、硬件诊断工具 | `home/cli/diagnostics.nix` |
| 网络诊断工具 | `home/cli/network.nix` |
| Git、Neovim、tmux | `home/programs/` |
| 每台机器的软件选择 | `machines/<name>/home.nix` |
| Home Manager 接入 | `modules/home-manager.nix` |

新增软件时，先在 `home/` 编写配置，例如：

```nix
# home/programs/sqlite.nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.sqlite ];
}
```

再在需要该软件的 `machines/<name>/home.nix` 的 imports 中加入 `../../home/programs/sqlite.nix`。取消导入即可改变该机器的软件选择，共享软件文件保持独立。

Git 作者信息统一写入 `home/programs/git.nix` 的 `programs.git.settings.user`，其他程序的选项也放在对应软件文件。

## 软件源与兼容版本

系统和基础工具使用 `nixos-26.05`，Home Manager 使用匹配的 `release-26.05`。用户环境沿用系统包集；`pkgsUnstable` 作为独立参数传入，不全局替换包集。

stable 包使用 `pkgs.xxx`；Git、Neovim、fzf、bat、eza、ripgrep、fd、btop 使用 `pkgsUnstable.xxx`。`programs.*` 模块负责安装已启用的软件，避免在 `home.packages` 重复声明。

```bash
nix flake update nixpkgs-unstable
nix flake update nixpkgs home-manager
```

版本只在主动更新锁文件后改变。`home.stateVersion` 与 `system.stateVersion` 保持 `26.05`，不随软件版本升级。冲突 dotfile 备份为 `.hm-backup`；遇到冲突时检查 `home-manager-tau.service` 日志和已有备份。
