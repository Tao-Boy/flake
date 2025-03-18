{inputs, pkgs, ...}: {
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false;
    plugins = [
       pkgs.hyprlandPlugins.hyprspace
    ];
    extraConfig = builtins.readFile ./hyprland.conf;
  };
}
