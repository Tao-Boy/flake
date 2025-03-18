{pkgs, ...}: {
  imports = [
    ./browser.nix
    ./kitty.nix
    ./hyprland
    ./gtk.nix
    ./fonts.nix
    ./fcitx5.nix
    ./xdg.nix
    ./zathura.nix
  ];
}
