{ inputs, pkgs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    sharedModules = [ ../home ];
    extraSpecialArgs.pkgsUnstable =
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  };
}
