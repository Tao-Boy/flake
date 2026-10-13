{ inputs, pkgs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    overwriteBackup = true;
    sharedModules = [ ../home ]; # 所有用户共用 home/default.nix
    extraSpecialArgs.pkgsUnstable =
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  };
}
