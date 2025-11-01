{pkgs, ...}: let
  #LxgwWenKai = pkgs.callPackage ../../pkgs/LxgwWenKai.nix {};
in {
  home.packages = with pkgs; [
    source-sans
    source-serif
    source-han-sans
    source-han-serif
    nerd-fonts.jetbrains-mono
    #LxgwWenKai
  ];

  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts = {
    serif = ["Source Han Serif SC" "Source Han Serif TC" "Noto Color Emoji"];
    sansSerif = ["Source Han Sans SC" "Source Han Sans TC" "Noto Color Emoji"];
    monospace = ["JetBrainsMono Nerd Font"];
    emoji = ["Noto Color Emoji"];
  };
}
