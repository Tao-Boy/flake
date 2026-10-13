{ pkgs, pkgsUnstable, ... }:
{
  home.packages = [
    pkgs.htop
    pkgs.ncdu
    pkgs.lsof
    pkgs.strace
    pkgs.sysstat
    pkgs.pciutils
    pkgs.usbutils
    pkgsUnstable.btop
  ];
}
