{...}: {
  services.wpaperd = {
    enable = true;
    settings = {
      eDP-1 = {
        path = "~/Pictures";
        apply-shadow = true;
      };
    };
  };
}
