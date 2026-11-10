# Home Manager

所有用户软件和 dotfiles 均放在 `home/`，由 Home Manager 随 NixOS 重建激活。主机在自己的 `home.nix` 中逐项选择：

```nix
# hosts/vps/home.nix
imports = [
  ../../home/shell.nix
  ../../home/cli/utilities.nix
  ../../home/programs/git.nix
];
```

公共兼容版本由 `modules/nixos/base/home-manager.nix` 统一加载，主机只选择软件。Home Manager 的共享模块是 `home/default.nix`。

| 内容 | 位置 |
| --- | --- |
| 公共兼容版本 | `home/default.nix` |
| Bash、fzf、bat、eza | `home/shell.nix` |
| 文件、下载、归档工具 | `home/cli/utilities.nix` |
| 进程、磁盘、硬件诊断工具 | `home/cli/diagnostics.nix` |
| 网络诊断工具 | `home/cli/network.nix` |
| Git、Neovim、tmux、npm、pi-web 服务 | `home/programs/` |
| 每台机器的软件选择 | `hosts/<name>/home.nix` |
| Home Manager 接入 | `modules/nixos/base/home-manager.nix` |

新增软件时，先在 `home/` 编写配置，例如：

```nix
# home/programs/sqlite.nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.sqlite ];
}
```

再在需要它的 `hosts/<name>/home.nix` 的 imports 中加入 `../../home/programs/sqlite.nix`。机器的系统入口导入 Home Manager 模块，并设置 `home-manager.users.tau = ./home.nix`。代理开关 `proxy-on` / `proxy-off` 由系统的代理模块提供，不属于用户软件。取消软件导入即可改变该机器的软件选择，共享软件文件保持独立。

Git 作者信息统一写入 `home/programs/git.nix` 的 `programs.git.settings.user`，其他程序的选项也放在对应软件文件。

pi 与 pi-web 不由 Nix 管理，自行用 npm 全局安装（`npm i -g ...`，安装到 `~/.npm/bin`，家目录位于持久化的 ext4 根文件系统中）。`home/programs/pi.nix` 只定义用户服务 `pi-web`，它读取 `~/.config/pi-web/server.env`，在 `users.nix` 开启 linger 后随开机启动。
