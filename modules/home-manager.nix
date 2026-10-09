{ config, lib, pkgsUnstable, ... }:
{
  config = lib.mkIf config.fleet.enable {
    home-manager = {
      # User modules share stable pkgs and opt into pkgsUnstable per package.
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit pkgsUnstable; };
      # Preserve pre-existing dotfiles; an existing backup causes activation to stop.
      backupFileExtension = "hm-backup";
      users.${config.fleet.access.adminUser} = import ../home;
    };
  };
}
