{ username, pkgs, ... }: {
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJRL4+A52F86h+XgyqLK/r2Wd1mTlaGDWLjhyz/fb1PQ"
    ];
    hashedPassword =
      "$y$j9T$hiGd6H2rZ8rXrFmI8n4U51$zaW1QQvS4Qt5xdXbdr6zwqm8/ryxqMicS.7g8kIYYdB";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
  nix.settings.allowed-users = [ "${username}" ];
}
