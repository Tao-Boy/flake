# Home Manager 与双软件源

NixOS 负责系统服务、账号和基础系统工具；Home Manager 负责管理员的交互式软件和配置，随系统重建一起激活。

## 配置在哪里

| 内容 | 文件 |
| --- | --- |
| 系统必需工具 | `modules/base/packages.nix` |
| Bash、fzf、bat、eza | `home/base/shell.nix` |
| 用户包、Git、Neovim、tmux | `home/base/tools.nix` |
| 当前主机的用户差异 | `home/hosts/vps.nix` |
| Home Manager 接入与参数 | `lib/nixos-system.nix` |

OpenSSH、sudo、iproute2、iputils、util-linux 与 nixos-rebuild 由 NixOS 自带模块提供；`modules/base/packages.nix` 只添加 DNS/硬件诊断工具。curl、jq、压缩工具、htop、ncdu、rsync、网络诊断等日常工具均在用户环境中。

## stable / unstable 的分工

`nixpkgs` 跟随 `nixos-26.05`，系统服务和基础工具保持稳定。`home-manager` 跟随 `release-26.05` 且 follows 稳定 nixpkgs。`nixpkgs-unstable` 是独立输入，只有明确选择的用户工具使用它：

- stable：curl、wget、jq、yq、rsync、归档工具、htop、ncdu、strace、tmux 等。
- unstable：Git、Neovim、fzf、bat、eza、ripgrep、fd、btop。

`useGlobalPkgs = true` 让 Home Manager 的 `pkgs` 使用系统稳定包集；`pkgsUnstable` 通过 `extraSpecialArgs` 单独传入，没有全局覆盖或 overlay。

`home/base/tools.nix` 的包列表每行写一个完整包名：`pkgs.xxx` 是 stable，`pkgsUnstable.xxx` 是 unstable。添加软件时直接增加一行。已配置的 `programs.*` 会安装对应软件，不要再重复加入 `home.packages`。

例如给当前主机添加用户工具：

```nix
# home/hosts/vps.nix
{ pkgs, pkgsUnstable, ... }:
{
  imports = [ ../base/default.nix ];
  home.packages = [
    pkgs.sqlite
    pkgsUnstable.just
  ];
  programs.git.settings.user = {
    name = "Your Name";
    email = "you@example.com";
  };
}
```

`programs.*.package = pkgsUnstable.<软件>` 可显式选择 unstable；没有特别需要时使用默认 stable。

## 激活与更新

```bash
nix develop
nixos-rebuild test --flake .#vps --target-host ops@YOUR_SERVER --sudo
# 另开 SSH 会话验证
nixos-rebuild switch --flake .#vps --target-host ops@YOUR_SERVER --sudo
```

Home Manager 使用 `useUserPackages = true`，软件通过 NixOS 的用户 profile 提供。配置碰到已有 dotfile 时保留 `.hm-backup` 备份；如有冲突，检查对应 `home-manager-ops.service` 的日志和已有备份。

`home.stateVersion` 与 `system.stateVersion` 保持 `26.05`。这两个值控制兼容行为，不随包版本更新自动修改。更改管理员用户名会涉及账号、家目录和数据迁移，不能只重命名配置变量就假定数据已经迁移。

## 独立更新锁文件

```bash
# 只更新常更新的用户软件
nix flake update nixpkgs-unstable

# stable 与匹配的 Home Manager 一起更新
nix flake update nixpkgs home-manager

# 全部输入
nix flake update
```

先审查 `flake.lock`，再运行检查和构建，最后远程激活。选了 unstable 也只会在主动更新锁文件后改变版本。

```bash
nix flake check --no-build --no-write-lock-file
nix build --no-write-lock-file .#checks.x86_64-linux.home
nix build --no-write-lock-file .#nixosConfigurations.vps.config.system.build.toplevel
```

用户配置统一跟随 NixOS 管理，无需独立的 `home-manager switch`、额外用户 flake 或重复软件列表。
