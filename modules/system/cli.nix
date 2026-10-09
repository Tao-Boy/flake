{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.fleet.enable {
    # Stable system administration and recovery tools available to root.
    # Interactive applications and optional diagnostics belong in Home Manager.
    environment.systemPackages = with pkgs; [
      openssh sudo util-linux
      iproute2 iputils dnsutils
      pciutils usbutils
      nixos-rebuild
    ];
  };
}
