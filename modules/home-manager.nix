{ inputs, pkgs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true; # 与系统使用同一份稳定版软件源 pkgs
    useUserPackages = true; # 用户软件安装到 /etc/profiles/per-user
    backupFileExtension = "hm-backup"; # 已有同名 dotfile 时改名备份
    sharedModules = [ ../home ]; # 所有用户共用 home/default.nix
    # home/ 中可以通过 pkgsUnstable.xxx 使用 unstable 软件源。
    extraSpecialArgs.pkgsUnstable =
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  };
}
