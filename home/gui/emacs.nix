{
  pkgs,
  inputs,
  ...
}: {
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-git-pgtk; # replace with pkgs.emacs-gtk if desired
    extraPackages = epkgs: [ epkgs.lsp-bridge ];
    extraConfig = ''
      (setq rime-librime-root "${pkgs.librime}"
            rime-emacs-module-header-root "${pkgs.emacs-git-pgtk}/include"
            rime-share-data-dir "${pkgs.rime-ice}/share/rime-data")
    '';
  };
}