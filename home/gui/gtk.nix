{pkgs, ...}: {
  gtk = {
    enable = true;
    font = {
      name = "Maple Mono";
      size = 12;
    };
    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };
    cursorTheme = {
      name = "macOS";
      package = pkgs.apple-cursor;
      size = 24;
    };
  };

  home.pointerCursor = {
    name = "macOS";
    package = pkgs.apple-cursor;
    size = 24;
    gtk.enable = true;
  };
}
