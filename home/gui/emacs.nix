{
  pkgs,
  inputs
  ...
}: {
  nixpkgs.overlays = [
    inputs.emacs-overlay.overlays.default
  ];
  home.packages = with pkgs; [
    emacs-git
  ];
}