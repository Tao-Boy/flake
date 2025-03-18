{
  inputs,
  lib,
  nixos-modules,
  home-modules ? [],
  vars,
  hostName,
  ...
}: let
  inherit (inputs) nixpkgs home-manager;
  specialArgs = {inherit inputs vars hostName;};
in
  nixpkgs.lib.nixosSystem {
    inherit specialArgs;
    system = "x86_64-linux";
    modules =
      nixos-modules
      ++ (
        lib.optionals ((lib.lists.length home-modules) > 0)
        [
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users."${vars.username}".imports = home-modules;
          }
        ]
      );
  }
