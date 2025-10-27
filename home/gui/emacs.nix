{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    emacs-git-pgtk
  ];
}