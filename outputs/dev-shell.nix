{ pkgs }:
pkgs.mkShell {
  packages = [
    pkgs.git
    pkgs.openssh
    pkgs.nix
    pkgs.nixos-anywhere
    pkgs.nixos-rebuild
    pkgs.nixfmt
    pkgs.statix
    pkgs.deadnix
  ];
}
