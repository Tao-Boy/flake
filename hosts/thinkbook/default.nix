{inputs, ...}: {
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware.nix
    ./disk.nix
    ../../modules
    ../../home
  ];
}
