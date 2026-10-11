{ config, lib, ... }:
let
  cfg = config.local.admin;
in
{
  # 管理员身份的选项定义；具体取值写在仓库根目录的 users.nix。
  options.local.admin = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "tau";
      description = "管理员用户名；系统账号、SSH、Nix 信任用户与 Home Manager 共用。";
    };
    sshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ ];
      description = "管理员的 SSH 公钥，每项为 .pub 文件的完整一行。";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.sshKeys != [ ];
        message = "local.admin.sshKeys 为空：请先在 users.nix 填写管理员的 SSH 公钥。";
      }
    ];

    # 固定 UID 并锁定密码；管理员只能使用 SSH 公钥登录。
    users = {
      mutableUsers = false;
      users = {
        root.hashedPassword = "!";
        ${cfg.name} = {
          isNormalUser = true;
          uid = 1000;
          extraGroups = [ "wheel" ];
          hashedPassword = "!";
          openssh.authorizedKeys.keys = cfg.sshKeys;
        };
      };
    };
    security.sudo.wheelNeedsPassword = false;
    nix.settings.trusted-users = [ cfg.name ];
  };
}
