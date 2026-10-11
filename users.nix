{
  imports = [ ./modules/nixos/admin.nix ];

  # 所有机器共用的管理员身份；修改后系统账号、SSH 和 Home Manager 同步生效。
  local.admin = {
    name = "tau";
    # 粘贴 .pub 文件的完整一行；保持空列表时，求值会以断言阻止无凭据部署。
    sshKeys = [ ];
  };
}
