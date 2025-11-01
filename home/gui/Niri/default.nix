{pkgs,inputs,...}: {
  imports = [
    inputs.niri.homeModules.niri
    ./fuzzel.nix
    ./swaybg.nix
  ];
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };
}
