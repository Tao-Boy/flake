{
  username,
  pkgs,
  ...
}:
{
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    hashedPassword = "$y$j9T$hiGd6H2rZ8rXrFmI8n4U51$zaW1QQvS4Qt5xdXbdr6zwqm8/ryxqMicS.7g8kIYYdB";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
  nix.settings.allowed-users = [ "${username}" ];
}
