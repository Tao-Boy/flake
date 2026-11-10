{ self, nixpkgs, ... }@inputs:
let
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  forEachSystem = nixpkgs.lib.genAttrs systems;

  packagesFor =
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      install = pkgs.nixos-anywhere;
      inherit (pkgs) sops xray;
    };

  devShellFor =
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
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
          pkgs.xray
        ];
      };
    };

  formatterFor = system: nixpkgs.legacyPackages.${system}.nixfmt-tree;
in
{
  nixosConfigurations = {
    vps = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [ ../hosts/vps ];
    };

    oracle-arm = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit inputs; };
      modules = [ ../hosts/oracle-arm ];
    };
  };

  # Build checks for the host platform locally; the ARM host is exposed under
  # checks.aarch64-linux for an ARM builder or CI matrix.
  checks = {
    x86_64-linux.vps = self.nixosConfigurations.vps.config.system.build.toplevel;
    aarch64-linux.oracle-arm = self.nixosConfigurations.oracle-arm.config.system.build.toplevel;
  };

  packages = forEachSystem packagesFor;
  formatter = forEachSystem formatterFor;
  devShells = forEachSystem devShellFor;
}
