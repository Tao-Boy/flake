inputs:
let
  inherit (inputs.nixpkgs) lib;
  users = import ../users.nix;
  machines = import ../machines;
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs.legacyPackages.${system};
in
{
  nixosConfigurations = lib.mapAttrs (
    name: machine:
    lib.nixosSystem {
      specialArgs = { inherit inputs users machine; };
      modules = [
        machine.module
        {
          nixpkgs.hostPlatform = lib.mkDefault machine.system;
          networking.hostName = lib.mkDefault name;
        }
      ];
    }
  ) machines;

  packages.${system} = {
    inherit (pkgs) nixos-anywhere;
    install = pkgs.nixos-anywhere;
    default = pkgs.nixos-anywhere;
  };
  formatter.${system} = pkgs.nixfmt;
  devShells.${system}.default = pkgs.mkShell {
    packages = [
      pkgs.git
      pkgs.openssh
      pkgs.nix
      pkgs.nixos-anywhere
      pkgs.nixos-rebuild
      pkgs.nixfmt
      pkgs.statix
      pkgs.deadnix
    ];
  };
}
