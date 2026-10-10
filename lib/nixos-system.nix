{ inputs, users }:
name: machine:
inputs.nixpkgs.lib.nixosSystem {
  inherit (machine) system;
  specialArgs = { inherit users; };
  modules = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    machine.module
    {
      networking.hostName = inputs.nixpkgs.lib.mkDefault name;
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";
        extraSpecialArgs = {
          inherit users;
          pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${machine.system};
        };
        users.${users.username} = machine.home;
      };
    }
  ];
}
