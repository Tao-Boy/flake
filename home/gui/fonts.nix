{pkgs, ...}: {
  home.packages = with pkgs; [
    noto-fonts-emoji # 彩色的表情符号字体
    source-sans # 无衬线字体，不含汉字。字族名叫 Source Sans 3 和 Source Sans Pro，以及带字重的变体，加上 Source Sans 3 VF
    source-serif # 衬线字体，不含汉字。字族名叫 Source Code Pro，以及带字重的变体
    source-han-sans # 思源黑体
    source-han-serif # 思源宋体
    nerd-fonts.jetbrains-mono
    maple-mono
  ];

  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts = {
    serif = ["Source Han Serif SC" "Source Han Serif TC" "Noto Color Emoji"];
    sansSerif = ["Source Han Sans SC" "Source Han Sans TC" "Noto Color Emoji"];
    monospace = ["JetBrainsMono Nerd Font"];
    emoji = ["Noto Color Emoji"];
  };
}
