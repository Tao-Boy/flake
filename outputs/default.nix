# inputs 包含 flake.nix 中声明的软件源。
inputs:
let
  # 本仓库只支持 x86_64-linux；部署工具使用稳定源。
  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
  myvars = import ../vars/default.nix;

  # 添加主机时，复制这段并修改名称、系统入口和用户入口。
  vpsSystem = import ../lib/nixos-system.nix {
    inputs = inputs;
    myvars = myvars;
    name = "vps";
    nixosModule = ../hosts/vps/default.nix;
    homeModule = ../home/hosts/vps.nix;
  };

  # 安装脚本只调用 nixos-anywhere，所有参数使用上游原有语法。
  install = pkgs.writeShellApplication {
    name = "vps-install";
    meta.mainProgram = "vps-install";
    runtimeInputs = [ pkgs.nixos-anywhere ];
    text = builtins.readFile ../scripts/vps.sh;
  };
in
{
  nixosConfigurations.vps = vpsSystem;

  formatter."x86_64-linux" = pkgs.nixfmt;

  # nix run .#install 与 nix run .#nixos-anywhere 都接受上游安装参数。
  packages."x86_64-linux" = {
    install = install;
    nixos-anywhere = pkgs.nixos-anywhere;
    default = install;
  };

  # nix develop 提供本地开发和远程重建所需的工具。
  devShells."x86_64-linux".default = pkgs.mkShell {
    packages = [
      pkgs.git
      pkgs.openssh
      pkgs.nix
      pkgs.nixos-anywhere
      pkgs.nixos-rebuild
      pkgs.nixfmt
      pkgs.statix
      pkgs.deadnix
      pkgs.shellcheck
    ];
  };

  # 构建安装包时会自动运行 ShellCheck；home 构建用户环境。
  checks."x86_64-linux" = {
    install = install;
    home = vpsSystem.config.home-manager.users.${myvars.username}.home.activationPackage;
  };
}
