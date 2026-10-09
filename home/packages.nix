{ pkgs, pkgsUnstable, ... }:
{
  home.packages =
    (with pkgs; [
      # Stable user utilities and optional diagnostics.
      curl wget jq yq-go tree less rsync
      unzip zip gnutar gzip xz zstd
      htop ncdu lsof file strace sysstat
      mtr tcpdump nmap socat ethtool
    ])
    ++ (with pkgsUnstable; [
      # Selected frequently updated terminal tools.
      ripgrep fd btop
    ]);

  # Applications configured through programs.* are installed by those modules;
  # keep them out of home.packages to avoid duplicate stable/unstable binaries.
}
