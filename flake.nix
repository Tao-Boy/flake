{
  description = "NixOS machines and Home Manager configurations";

  # inputs：配置依赖的软件源；实际版本由 flake.lock 锁定。
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # 仅供 home/ 中选用的用户软件使用。
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # follows 让外部模块共用上面的稳定 nixpkgs。
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # outputs：可构建的系统，以及 nix run / nix develop 使用的工具。
  outputs =
    inputs:
    let
      system = "x86_64-linux"; # 本机工具的平台
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    {
      # .#vps 对应这台机器；新增机器时复制这一段并修改名称和路径。
      nixosConfigurations.vps = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; }; # 让模块可以使用 inputs.disko 等外部模块
        modules = [ ./machines/vps ];
      };

      # CI 构建 vps 系统时，用 .github/ci.nix 补上占位公钥和示例配置。
      checks.${system}.vps =
        (inputs.self.nixosConfigurations.vps.extendModules { modules = [ ./.github/ci.nix ]; })
        .config.system.build.toplevel;

      packages.${system} = {
        install = pkgs.nixos-anywhere; # nix run .#install：远程安装
        # LiveCD 临时代理用到的工具，版本与系统一致。
        inherit (pkgs) sops xray;
      };

      formatter.${system} = pkgs.nixfmt; # nix fmt

      # nix develop：进入包含安装、加密和格式化工具的终端环境。
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.git
          pkgs.openssh
          pkgs.nixos-anywhere
          pkgs.nixos-rebuild
          pkgs.nixfmt
          pkgs.sops
          pkgs.age
          pkgs.xray
        ];
      };
    };
}
