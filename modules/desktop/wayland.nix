{pkgs, ...}:
{
  programs.hyprland.enable = true;

  xdg = {
    portal = {
      enable = true;
      config = {
        hyprland.default = ["gtk" "hyprland"];
    };

      xdgOpenUsePortal = false;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];
    };
  };
}
