{ lib, ... }:
{
  imports = [
    ../base/users.nix
    ../base/core.nix
    ../base/networking.nix
    ../base/security.nix
    ./sops.nix
    ./ssh.nix
  ];

  time.timeZone = lib.mkDefault "UTC";
}
