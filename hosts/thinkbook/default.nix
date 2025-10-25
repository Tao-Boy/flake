{inputs, ...}: {
  imports = [
    ./hardware.nix
    inputs.disko.nixosModules.disko
    ./disk.nix
    ../../modules
    #../../home
  ];
}
