{ lib, ... }:
{
  imports = [
    ./core/nix.nix
    ./core/users.nix
    ./core/packages.nix
    ./networking
    ./security/ssh.nix
    ./security/hardening.nix
    ./services/maintenance.nix
  ];

  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";
  documentation.nixos.enable = lib.mkDefault false;
  environment.defaultPackages = lib.mkDefault [ ];
}
