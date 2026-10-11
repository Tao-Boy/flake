{
  # 系统中唯一的用户：SSH 登录、sudo 和 Home Manager 都使用它。
  # 修改用户名时，同时修改 machines/vps/default.nix 中的 home-manager.users.tau。
  users.mutableUsers = false; # 用户只由本文件定义，不能用 passwd/useradd 修改
  users.users.tau = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ]; # wheel 组可以使用 sudo
    # 粘贴 .pub 文件的完整一行，例如 "ssh-ed25519 AAAA... me@laptop"。
    openssh.authorizedKeys.keys = [ ];
  };

  # 用户没有密码，只能用 SSH 公钥登录；sudo 因此不询问密码。
  security.sudo.wheelNeedsPassword = false;
  # 允许该用户远程部署（nixos-rebuild --target-host）。
  nix.settings.trusted-users = [ "@wheel" ];
}
