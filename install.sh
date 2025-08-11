#! /bin/bash
nix run github:nix-community/nixos-anywhere -- \
  --kexec "http://hk-proxy.gitwarp.com/https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz" \
  --flake .#vps \
  --target-host root@111.231.169.197
