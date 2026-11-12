{
  self,
  nixpkgs,
  nixpkgs-unstable,
  ...
}@inputs:
let
  inherit (nixpkgs) lib;

  # 主机名和架构只在这里登记；系统入口和检查由此生成。
  hosts = {
    vps-pi = "x86_64-linux";
    vps-dev = "x86_64-linux";
    oracle-arm = "aarch64-linux";
  };
  systems = lib.unique (builtins.attrValues hosts);
  forEachSystem =
    f:
    lib.genAttrs systems (
      system:
      f {
        inherit system;
        pkgs = nixpkgs.legacyPackages.${system};
        pkgsUnstable = nixpkgs-unstable.legacyPackages.${system};
      }
    );
in
{
  nixosConfigurations = lib.mapAttrs (
    name: system:
    lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        (../hosts + "/${name}")
        {
          networking.hostName = name;
          nixpkgs.hostPlatform = system;
        }
      ];
    }
  ) hosts;

  # 每个架构只检查属于该架构的主机，适用于本机构建或 CI matrix。
  checks = forEachSystem (
    { system, ... }:
    lib.mapAttrs (name: _: self.nixosConfigurations.${name}.config.system.build.toplevel) (
      lib.filterAttrs (_: hostSystem: hostSystem == system) hosts
    )
  );

  packages = forEachSystem (
    { pkgs, pkgsUnstable, ... }:
    {
      install = pkgs.nixos-anywhere;
      inherit (pkgs) sops;
      xray = pkgsUnstable.xray;
    }
  );

  devShells = forEachSystem (
    { pkgs, pkgsUnstable, ... }:
    {
      default = pkgs.mkShell {
        packages = [
          pkgs.git
          pkgs.openssh
          pkgs.nixos-anywhere
          pkgs.nixos-rebuild
          pkgs.nixfmt
          pkgs.sops
          pkgs.age
          pkgsUnstable.xray
        ];
      };
    }
  );

  formatter = forEachSystem ({ pkgs, ... }: pkgs.nixfmt-tree);
}
