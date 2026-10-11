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

  # outputs：可构建的系统、检查，以及 nix run / nix develop 使用的工具。
  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
      # 这里的平台用于工具和检查；机器的平台在机器配置中设置。
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};

      # 每台机器由共享的管理员身份和自己的目录组成。
      mkMachine =
        path:
        lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./users.nix
            path
          ];
        };

      # 构建机器的系统闭包与 disko 脚本；未填写的模板由 tests/template.nix 补齐。
      checkMachine =
        name:
        let
          inherit
            (inputs.self.nixosConfigurations.${name}.extendModules { modules = [ ./tests/template.nix ]; })
            config
            ;
        in
        pkgs.linkFarm "machine-${name}" (
          {
            system = config.system.build.toplevel;
          }
          // lib.optionalAttrs (config.system.build ? diskoScript) {
            disko = config.system.build.diskoScript;
          }
        );
    in
    {
      # .#vps 对应这台机器；新增机器时在这里加一行，并在 checks 中加入同名检查。
      nixosConfigurations = {
        vps = mkMachine ./machines/vps;
      };

      # nix flake check / CI 运行的检查。
      checks.${system} = {
        vps = checkMachine "vps";
        proxy = pkgs.testers.runNixOSTest (import ./tests/proxy.nix { inherit inputs; });
        lint =
          pkgs.runCommand "lint"
            {
              nativeBuildInputs = [
                pkgs.nixfmt
                pkgs.statix
                pkgs.deadnix
              ];
            }
            ''
              cd ${inputs.self}
              nixfmt --check $(find . -name '*.nix')
              statix check .
              deadnix --fail .
              touch $out
            '';
      };

      packages.${system} = {
        install = pkgs.nixos-anywhere; # nix run .#install
        # 保留直接运行 nix run . 和 .#nixos-anywhere 的入口。
        default = pkgs.nixos-anywhere;
        # LiveCD 临时代理使用的锁定版本工具，可预先 nix copy 到目标。
        inherit (pkgs) nixos-anywhere sops xray;
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
          pkgs.xray
        ];
      };
    };
}
