{
  users.mutableUsers = false;
  users.users.tau = {
    isNormalUser = true;
    # 允许用户级 systemd 服务在未登录时继续运行。
    linger = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    # 两台主机共用这把用户公钥；对应私钥加密保存在 secrets/id_ed25519。
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDcnjSs5iTq6xQsj9IBPylw9TsLWxGJkEWq+99A874mQ"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
