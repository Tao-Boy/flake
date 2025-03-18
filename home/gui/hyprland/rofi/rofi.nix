{pkgs, ...}: {
  home.packages = [pkgs.rofi-wayland];

  xdg.configFile."rofi/theme.rasi".source = ./theme.rasi;
  xdg.configFile."rofi/config.rasi".source = ./config.rasi;
}
