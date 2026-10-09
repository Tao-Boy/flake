{ lib, ... }:
{
  fleet.enable = lib.mkDefault true;
  boot.kernel.sysctl = {
    "net.ipv4.tcp_syncookies" = lib.mkDefault 1;
    "net.ipv4.conf.all.accept_redirects" = lib.mkDefault 0;
    "net.ipv4.conf.default.accept_redirects" = lib.mkDefault 0;
    "net.ipv4.conf.all.send_redirects" = lib.mkDefault 0;
    "net.ipv6.conf.all.accept_redirects" = lib.mkDefault 0;
  };
  # Set forwarding only for hosts that actually route traffic or host containers.
}
