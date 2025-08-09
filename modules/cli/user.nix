{
  username,
  pkgs,
  ...
}:
{
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    hashedPassword = "$y$j9T$tx2NbJ8GjbBcB6E8G.9ez.$eSVvf9Djth8TXKMOoFpymakeY2N1KYS010uWBcd6bgB";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
  nix.settings.allowed-users = [ "${username}" ];
}
