{pkgs, ...}: {
  dconf = {
    enable = true;
    settings = {
      "org/gnome/mutter" = {
        experimental-features = ["scale-monitor-framebuffer"];
      };
      "org/gnome/mutter.x11-randr" = {
        current-workspace-scale = 1.25;
      };
      "org/gnome/shell" = {
        disable-user-extensions = false;
      };
      "org/gnome/desktop/interface" = {
        text-scaling-factor = 1;
        clock-show-weekday = true;
      };
    };
  };
}
