{
  username,
  pkgs,
  ...
}: {
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    hashedPassword = "$y$j9T$MwdWv2r5D.mhvBr2gh5Y7.$uzhfBLvVJzH09M.MmY6t9A.2S4n/N5ttHpwJVCnbmWD";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
  nix.settings.allowed-users = ["${username}"];
}
