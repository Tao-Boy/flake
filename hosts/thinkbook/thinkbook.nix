{
  inputs,
  lib,
  vars,
  ...
} @ args: let
  hostName = "thinkbook";
  mkSystem = import ../lib/mkSystem.nix;
  modules = {
    inherit hostName;
    nixos-modules = [
      ../modules
      ../overlay
    ];
    home-modules = [
      ../home
    ];
  };
in {
  "${hostName}" = mkSystem (modules // args);
}
