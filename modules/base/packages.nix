{ pkgs, ... }:
{
  # NixOS already provides OpenSSH, sudo, util-linux, iproute2, iputils and rebuild.
  # Keep only extra system diagnostics here; user applications live in home/base/.
  environment.systemPackages = with pkgs; [ dnsutils pciutils usbutils ];
}
