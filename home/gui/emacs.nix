{
  inputs,
  pkgs,
  ...
}: {
  imports = [ inputs.emacs-overlay.nixosModules.emacs ];
  home.packages = with pkgs; [
    emacs-git
  ];
}