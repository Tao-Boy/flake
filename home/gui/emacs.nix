{
  pkgs,
  ...
}: {
  nixpkgs.overlays = [ emacs-overlay.overlays.default ];
  home.packages = with pkgs; [
    emacs-git
  ];
}