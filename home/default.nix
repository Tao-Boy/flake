{
  hostName,
  vars,
  ...
}: {
  imports = [
    ./base
    (
      if hostName != "vm"
      then ./gui
      else []
    )
  ];

  home.username = "${vars.username}";
  home.homeDirectory = "/home/${vars.username}";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}
