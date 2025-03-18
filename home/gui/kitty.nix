{
  lib,
  pkgs,
  ...
}:
###########################################################
#
# Kitty Configuration
#
# Useful Hot Keys for Linux(replace `ctrl + shift` with `cmd` on macOS)):
#   1. Increase Font Size: `ctrl + shift + =` | `ctrl + shift + +`
#   2. Decrease Font Size: `ctrl + shift + -` | `ctrl + shift + _`
#   3. And Other common shortcuts such as Copy, Paste, Cursor Move, etc.
#
###########################################################
{
  programs.kitty = {
    enable = true;
    themeFile = "Catppuccin-Mocha";
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 16;
    };

    settings = {
      background_opacity = "0.85";
      enable_audio_bell = false;
      mouse_hide_wait = 60;
      tab_bar_edge = "top"; # tab bar on top
    };
  };
}
