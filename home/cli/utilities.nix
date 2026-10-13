{ pkgs, pkgsUnstable, ... }:
{
  home.packages = [
    pkgs.curl
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
}
