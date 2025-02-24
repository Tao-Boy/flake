{
  inputs,
  username,
  host,
}: {
  imports = [
    ./bootloader.nix
    ./hardware.nix
    ./network.nix
    ./pipewire.nix
    ./system.nix
    ./user.nix
    ./wayland.nix
  ];
}
