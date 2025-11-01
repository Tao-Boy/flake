{host, ...}: {
  imports = [
    ./bootloader.nix
    ./i18n.nix
    ./networking.nix
    ./nix.nix
    ./packages.nix
    ./user.nix
    ./zram.nix
    ./impermanence.nix
    ./audio.nix
  ];
}
