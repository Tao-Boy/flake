{ lib, myvars, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    max-jobs = lib.mkDefault 1;
    cores = lib.mkDefault 0;
    # 管理员已有免密码 sudo；信任此账号以接收本机构建后传入的包。
    trusted-users = [
      "root"
      myvars.username
    ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
    persistent = true;
  };
}
