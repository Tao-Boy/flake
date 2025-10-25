{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    emacs-git
  ];
}