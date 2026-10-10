{ lib, ... }:
{
  imports = [
    ../../modules/nixos/core/nix.nix
    ../../modules/nixos/core/users.nix
    ../../modules/nixos/core/packages.nix
  ];
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";
  documentation.nixos.enable = lib.mkDefault false;
  environment.defaultPackages = lib.mkDefault [ ];
}
