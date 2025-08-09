{pkgs, ...}: {
  gtk = {
    enable = true;

    font = {
      name = "Source Han Sans SC";
      package = pkgs.source-han-sans;
      size = 12;
    };

    cursorTheme = {
      name = "macOS";
      package = pkgs.apple-cursor;
      size = 24;
    };

    theme = {
      name = "WhiteSur-Dark-hdpi";
      package = pkgs.whitesur-gtk-theme;
    };
    iconTheme = {
      name = "WhiteSur-light";
      package = pkgs.whitesur-icon-theme; # 替换为提供该图标主题的 Nix 包
    };
  };
}
