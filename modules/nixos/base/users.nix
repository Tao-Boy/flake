{
  users.mutableUsers = false;
  users.users.tau = {
    isNormalUser = true;
    # 开机即启动用户级 systemd 服务（如 pi-web），无需先登录。
    linger = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDcnjSs5iTq6xQsj9IBPylw9TsLWxGJkEWq+99A874mQ"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
