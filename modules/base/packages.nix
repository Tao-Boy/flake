{ pkgs, ... }:
{
  # Stable system and recovery tools; user applications live in home/base/.
  environment.systemPackages = with pkgs; [
    openssh sudo util-linux
    iproute2 iputils dnsutils
    pciutils usbutils
    nixos-rebuild
  ];
}
