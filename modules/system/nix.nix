{ config, lib, ... }:
{
  config = lib.mkIf config.fleet.enable {
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      # Small VPSs often have too little RAM for parallel compilation.
      max-jobs = lib.mkDefault 1;
      cores = lib.mkDefault 0;
      # This administrator already has passwordless sudo; trust allows receiving
      # unsigned closures built locally by nixos-rebuild over SSH.
      trusted-users = [ "root" config.fleet.access.adminUser ];
    };
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
      persistent = true;
    };
    system.autoUpgrade.enable = lib.mkDefault false;
  };
}
