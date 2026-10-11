{ lib, ... }:
{
  documentation.nixos.enable = lib.mkDefault false;
  environment.defaultPackages = lib.mkDefault [ ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    max-jobs = lib.mkDefault 1;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
