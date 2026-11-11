# Home Manager

用户软件和 dotfiles 放在 `home/`，由 Home Manager 随 NixOS 重建激活，目前仅 VPS 启用。Oracle ARM 通过 `modules/nixos/base/cli.nix` 直接安装系统维护所需的 Git、Neovim、tmux、下载归档、诊断和 SOPS 工具，所有用户都能使用。启用 Home Manager 的主机在自己的 `home.nix` 中逐项选择：

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
| Git、Neovim、tmux、npm | `home/programs/` |
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

pi CLI 仍可自行用 npm 全局安装（`npm i -g ...`，安装到 `~/.npm/bin`）。pi-web 改由系统模块 `modules/nixos/server/pi-web.nix` 使用 Podman 运行上游镜像，不再定义 Home Manager 用户服务，也不依赖宿主机的 npm 全局安装。容器仅挂载 `/home/tau/pi-workspace`，工作目录、容器 HOME、agent 数据和项目都放在这个独立工作区内；工具由镜像提供，不依赖宿主的 Home Manager 配置。环境文件由 SOPS 从 `secrets/server.env` 解密到 `/run/secrets/pi-web.env` 后交给 Podman。部署与更新见[可选服务](services.md)。
