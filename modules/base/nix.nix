{ lib, myvars, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    max-jobs = lib.mkDefault 1;
    cores = lib.mkDefault 0;
    # The administrator already has passwordless sudo and receives local closures.
    trusted-users = [ "root" myvars.username ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
    persistent = true;
  };
  system.autoUpgrade.enable = lib.mkDefault false;
}
