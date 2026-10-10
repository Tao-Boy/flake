# 用户环境与双软件源

NixOS 管理系统服务、账号和系统工具；Home Manager 管理交互式软件与 dotfiles，随 NixOS 重建激活。没有独立的用户 flake 或第二份软件列表。

## 配置位置

| 内容 | 位置 |
| --- | --- |
| 系统诊断工具 | `modules/nixos/core/packages.nix` |
| Bash、fzf、bat、eza | `modules/home/shell/default.nix` |
| 文件、下载、归档工具 | `modules/home/cli/utilities.nix` |
| 进程、磁盘和性能诊断 | `modules/home/cli/diagnostics.nix` |
| 网络诊断工具 | `modules/home/cli/network.nix` |
| Git、Neovim、tmux | `modules/home/programs/` |
| 服务器用户环境组合 | `profiles/home/server.nix` |
| 本机用户差异 | `machines/vps/home.nix` |
| Home Manager 接入 | `lib/nixos-system.nix` |

添加本机工具或作者信息：

```nix
# machines/vps/home.nix
{ pkgs, pkgsUnstable, ... }:
{
  imports = [ ../../profiles/home/server.nix ];
  home.packages = [ pkgs.sqlite pkgsUnstable.just ];
  programs.git.settings.user = {
    name = "Your Name";
    email = "you@example.com";
  };
}
```

## 软件源

系统与基础工具使用 `nixos-26.05`；Home Manager 使用匹配的 `release-26.05`。`useGlobalPkgs = true` 让用户环境沿用系统稳定包集；`pkgsUnstable` 单独传入，不全局覆盖包集。

stable 包以 `pkgs.xxx` 声明。Git、Neovim、fzf、bat、eza、ripgrep、fd、btop 显式选择 `pkgsUnstable.xxx`；其他原有工具保持 stable。已启用的 `programs.*` 模块负责安装软件，不再重复写入 `home.packages`。

```bash
nix flake update nixpkgs-unstable
nix flake update nixpkgs home-manager
# 或主动更新全部输入
nix flake update
```

审查锁文件，运行检查与构建，再进行远程 `test` / `switch`。使用 unstable 也只会在主动更新锁文件后改变版本。本次重构不更新现有锁定输入。

`home.stateVersion` 和 `system.stateVersion` 仍为 `26.05`，不随软件版本升级改变。Home Manager 的冲突 dotfile 备份为 `.hm-backup`；出现冲突时检查 `home-manager-tau.service` 日志和已有备份。
