{ lib, users, ... }:
{
  documentation.nixos.enable = lib.mkDefault false;
  environment.defaultPackages = lib.mkDefault [ ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    max-jobs = lib.mkDefault 1;
    trusted-users = [ users.username ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # 固定 UID 并锁定密码；管理员使用 SSH 公钥登录。
  users = {
    mutableUsers = false;
    users = {
      root.hashedPassword = "!";
      ${users.username} = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [ "wheel" ];
        hashedPassword = "!";
        openssh.authorizedKeys.keys = users.sshKeys;
      };
    };
  };
  security.sudo.wheelNeedsPassword = false;
}
