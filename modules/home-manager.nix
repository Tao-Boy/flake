{ inputs, pkgs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # 已存在的同名文件改名为 *.hm-backup 而不是让激活失败；旧备份直接覆盖。
    backupFileExtension = "hm-backup";
    overwriteBackup = true;
    sharedModules = [ ../home ]; # 所有用户共用 home/default.nix
    extraSpecialArgs = {
      inherit inputs;
      pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    };
  };
}
