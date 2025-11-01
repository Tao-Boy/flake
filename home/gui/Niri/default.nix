{pkgs,inputs,...}: {
  imports = [
    inputs.niri.homeModules.niri
    ./fuzzel.nix
    ./swaybg.nix
  ];
  programs.niri.package = pkgs.niri-unstable;

}
