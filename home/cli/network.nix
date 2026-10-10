{ pkgs, ... }:
{
  home.packages = [
    pkgs.mtr
    pkgs.tcpdump
    pkgs.nmap
    pkgs.socat
    pkgs.ethtool
    pkgs.dnsutils
  ];
}
