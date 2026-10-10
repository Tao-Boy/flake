{ lib, ... }:
{
  networking.nftables.enable = true;
  networking.firewall.enable = true;
  systemd.coredump.settings.Coredump = {
    Storage = "none";
    ProcessSizeMax = 0;
  };
  boot.kernel.sysctl = {
    "net.ipv4.tcp_syncookies" = lib.mkDefault 1;
    "net.ipv4.conf.all.accept_redirects" = lib.mkDefault 0;
    "net.ipv4.conf.default.accept_redirects" = lib.mkDefault 0;
    "net.ipv4.conf.all.send_redirects" = lib.mkDefault 0;
    "net.ipv6.conf.all.accept_redirects" = lib.mkDefault 0;
  };
}
