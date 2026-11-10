{ pkgs, pkgsUnstable, ... }:
{
  home.packages = [
    pkgs.curl
    pkgs.gcc
    pkgs.librime
    pkgsUnstable.typst
    pkgs.rime-data
    pkgs.gnumake
    pkgs.wget
    pkgs.jq
    pkgs.yq-go
    pkgs.tree
    pkgs.less
    pkgs.rsync
    pkgs.unzip
    pkgs.zip
    pkgs.gnutar
    pkgs.gzip
    pkgs.xz
    pkgs.zstd
    pkgs.file
    pkgsUnstable.ripgrep
    pkgsUnstable.fd
  ];
  programs.uv.enable = true;
}
