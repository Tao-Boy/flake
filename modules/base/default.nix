{
  inputs,
  hostName,
  pkgs,
  ...
}: {
  imports = [
    ./hardware
    inputs.disko.nixosModules.disko
    ./disk/${hostName}.nix
    ./i18n.nix
    ./networking.nix
    ./nix.nix
    ./packages.nix
    ./fhs.nix
    ./user.nix
    ./zram.nix
  ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
