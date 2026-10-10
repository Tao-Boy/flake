{ pkgs, pkgsUnstable, ... }:
{
  home.packages = [
    pkgs.htop
    pkgs.ncdu
    pkgs.lsof
    pkgs.strace
    pkgs.sysstat
    pkgsUnstable.btop
  ];
}
