{...}: {
  programs.hyprland = {
    enable = true;
  };
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      hyprland.default = [
        "hyprland"
      ];
    };
  };
}
