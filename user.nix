{
  # 系统中唯一的用户：SSH 登录、sudo 和 Home Manager 都使用它。
  # 修改用户名时，全局搜索 tau 一并替换（含 home-manager.users.tau 和 /home/tau/.ssh）。
  users.mutableUsers = false; # 用户只由本文件定义，不能用 passwd/useradd 修改
  users.users.tau = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ]; # wheel 组可以使用 sudo
    # 粘贴 .pub 文件的完整一行，例如 "ssh-ed25519 AAAA... me@laptop"。
    openssh.authorizedKeys.keys = [ ];
  };

  # ~/.ssh 保存 SSH 主机密钥和 age 私钥（/home 是持久分区）；每次开机确保目录归用户所有。
  systemd.tmpfiles.rules = [ "d /home/tau/.ssh 0700 tau users -" ];

  # 用户没有密码，只能用 SSH 公钥登录；sudo 因此不询问密码。
  security.sudo.wheelNeedsPassword = false;
  # 允许该用户远程部署（nixos-rebuild --target-host）。
  nix.settings.trusted-users = [ "@wheel" ];
}
