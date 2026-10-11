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
      # 这里的平台用于安装器和开发工具；机器的平台在机器配置中设置。
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      users = import ./users.nix;
    in
    {
      # .#vps 对应这台机器；新增机器时复制此块并修改名称和路径。
      nixosConfigurations.vps = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs users; };
        modules = [ ./machines/vps ];
      };

      packages.${system} = {
        install = pkgs.nixos-anywhere; # nix run .#install
        proxy = pkgs.callPackage ./proxy { }; # nix run .#proxy
        proxy-setup = pkgs.callPackage ./proxy/setup.nix { }; # 初始化密文或 LiveCD
        # 保留直接运行 nix run . 和 .#nixos-anywhere 的入口。
        default = pkgs.nixos-anywhere;
        inherit (pkgs) nixos-anywhere;
      };

      formatter.${system} = pkgs.nixfmt; # nix fmt
      devShells.${system}.default = pkgs.mkShell {
        # nix develop：进入包含安装、加密和检查工具的终端环境。
        packages = [
          pkgs.git
          pkgs.openssh
          pkgs.nix
          pkgs.nixos-anywhere
          pkgs.nixos-rebuild
          pkgs.nixfmt
          pkgs.statix
          pkgs.deadnix
          pkgs.sops
          pkgs.age
        ];
      };
    };
}
