# Home Manager 与双软件源

## 软件来源与安装层级

系统使用 `nixpkgs` 的 `nixos-26.05`。Home Manager 使用对应的 `release-26.05` 分支，并通过 `inputs.nixpkgs.follows = "nixpkgs"` 共享同一稳定源。

`nixpkgs-unstable` 指向 `nixos-unstable`，作为独立的 `pkgsUnstable` 传入用户模块。不覆盖系统 `pkgs`，也不把整个 Home Manager 包集切换到 unstable。四个输入都在 `flake.lock` 中固定，unstable 不会在每次重建时自动漂移。

| 安装层级 | 来源 | 当前用途 |
| --- | --- | --- |
| NixOS `environment.systemPackages` | stable | SSH、sudo、磁盘/网络/硬件基础工具、nixos-rebuild |
| Home Manager `home.packages` | stable | curl/wget、jq/yq、归档、htop/ncdu、可选网络/进程诊断 |
| Home Manager `home.packages` | unstable | ripgrep、fd、btop |
| Home Manager `programs.*` | unstable | Neovim、Git、fzf、bat、eza，同时管理程序配置 |
| Home Manager `programs.tmux` | stable | tmux 与其配置 |
| 部署脚本及开发 shell | stable | 独立的项目工具环境，不安装到管理员的 Home Manager profile |

NixOS 服务模块自行声明服务依赖；服务软件仍由 NixOS 管理。用户常用软件仅安装到配置管理员的 profile，root 不继承该用户的 Bash 别名或编辑器设置。

## 文件组织

```text
modules/home-manager.nix         # 集成、用户选择、pkgsUnstable 参数和文件备份策略
home/default.nix                # 用户模块组合与 home.stateVersion
home/packages.nix               # 稳定/unstable 用户包清单
home/programs/shell.nix          # Bash、fzf、bat、eza
home/programs/git.nix            # Git 软件版本与默认行为
home/programs/neovim.nix         # unstable Neovim，VPS 默认关闭额外语言 provider
home/programs/tmux.nix           # stable tmux
```

启用 `home-manager.useGlobalPkgs = true` 与 `useUserPackages = true`。管理员用户名及 home 目录从 NixOS 账户自动继承，软件安装到系统维护的用户 profile（通常为 `/etc/profiles/per-user/<用户名>`）。

`home.stateVersion` 独立记录首次使用 Home Manager 的兼容状态，当前为 26.05；不要因升级输入而自动增加它，也不要将它与 `system.stateVersion` 的修改绑定。

## 添加或调整用户软件

无配置的稳定源应用添加到 `home/packages.nix` 的 `with pkgs` 清单；需要较新版本的工具添加到 `with pkgsUnstable` 清单。

对于 Home Manager 已有程序模块的应用，优先使用 `programs.*`：

```nix
{ pkgsUnstable, ... }:
{
  programs.git = {
    enable = true;
    package = pkgsUnstable.git;
  };
}
```

该模块会同时安装 Git 并生成配置，不要再把另一个 Git 添加到 `home.packages` 或系统包中，以免 stable/unstable 二进制冲突。

Home Manager 的模块与选项定义来自稳定的 release 分支；为某个程序指定 unstable 的 `package` 只改变其软件版本。若新版软件行为发生不兼容变化，应先调整程序配置并重新验证，不要通过全局 overlay 替换系统依赖。

主机专用设置可放在 host 中，例如填写自己的 Git 作者信息：

```nix
{ config, ... }:
{
  home-manager.users.${config.fleet.access.adminUser}.programs.git.settings.user = {
    name = "你的名字";
    email = "你使用的提交邮箱";
  };
}
```

## 应用与更新

采用 NixOS 集成模式，统一通过现有部署入口：

```bash
git add home modules flake.nix flake.lock
nix flake check --no-build
nix build --no-link .#checks.x86_64-linux.home
nix run .#rebuild -- vps ops@SERVER_IP --action test
# 验证第二个 SSH 会话和用户环境。
nix run .#rebuild -- vps ops@SERVER_IP --action switch
```

实际管理员更名时，替换 SSH 目标中的 `ops`。不需要另外安装 standalone Home Manager，也不需要单独运行 `home-manager switch`。

仅更新 unstable：

```bash
nix flake update nixpkgs-unstable
git diff -- flake.lock
nix flake check --no-build
nix build --no-link .#checks.x86_64-linux.home
```

系统稳定源及 Home Manager 的锁定版本不会随这条单输入更新命令变化。更新 Home Manager 用 `nix flake update home-manager`；更新全部输入用 `nix flake update`。

## 文件冲突与排错

Home Manager 会把已有的受管 dotfiles 备份为 `*.hm-backup`，不会强制覆盖同名备份。若 activation 失败，查看：

```bash
systemctl status home-manager-ops
journalctl -u home-manager-ops -b
ls -l ~/.bashrc ~/.gitconfig ~/.tmux.conf
```

用户名更名时使用对应的 `home-manager-<用户名>` 服务。核对旧文件与备份，合并需要保留的内容，再重建；不要盲目删除备份。

系统回滚后，Home Manager 集成服务也会使用相应 generation 的配置；已有备份及应用数据不是 Nix generations 的一部分，仍需要独立保管。

用户可选诊断软件位于管理员 profile；执行需要 root 的工具时，可以明确使用已安装的程序路径，例如：

```bash
sudo "$(command -v tcpdump)" -i ens3
```

确认程序由受信任的声明式配置安装，不对任意下载的脚本使用 sudo。
