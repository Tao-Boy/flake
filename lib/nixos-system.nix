{ inputs, myvars }:
{ name, nixosModule, homeModule }:
let
  system = "x86_64-linux";
  pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${system};
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit myvars; };
  modules = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    nixosModule
    {
      networking.hostName = inputs.nixpkgs.lib.mkDefault name;
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";
        extraSpecialArgs = { inherit myvars pkgsUnstable; };
        users.${myvars.username} = import homeModule;
      };
    }
  ];
}
