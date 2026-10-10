{ inputs, users }:
name: machine:
inputs.nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs users machine; };
  modules = [
    machine.module
    {
      nixpkgs.hostPlatform = inputs.nixpkgs.lib.mkDefault machine.system;
      networking.hostName = inputs.nixpkgs.lib.mkDefault name;
    }
  ];
}
