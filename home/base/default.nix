{ lib, ... }:
{
  imports = [ ./shell.nix ./tools.nix ];
  # Independent from system.stateVersion; preserve after first Home Manager use.
  home.stateVersion = lib.mkDefault "26.05";
}
