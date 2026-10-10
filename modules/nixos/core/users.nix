{ users, ... }:
{
  # 账号由配置统一管理；"!" 表示锁定密码，管理员通过 SSH 公钥登录。
  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.${users.username} = {
    isNormalUser = true;
    # /var 每次重启清空，固定 UID 避免持久 home 的文件归属改变。
    uid = 1000;
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
    openssh.authorizedKeys.keys = users.sshKeys;
  };
  security.sudo.wheelNeedsPassword = false;

  # NixOS 模块的断言：禁止把管理员设置为 root，并验证用户名格式。
  assertions = [
    {
      assertion = users.username != "root" && builtins.match "[a-z_][a-z0-9_-]*" users.username != null;
      message = "users.username must be a normal Linux username other than root.";
    }
  ];

  warnings =
    if users.sshKeys == [ ] then
      [
        "请先在 users.nix 填写完整 SSH 公钥；空公钥模板无法通过 NixOS 登录保护断言。"
      ]
    else
      [ ];
}
