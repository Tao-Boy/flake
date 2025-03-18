{
  vars,
  pkgs,
  ...
}: {
  users.users.${vars.username} = {
    isNormalUser = true;
    description = "${vars.username}";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
}
