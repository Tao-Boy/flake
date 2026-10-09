{ ... }:
{
  imports = [
    ./options.nix
    ./system/base.nix
    ./system/nix.nix
    ./system/cli.nix
    ./system/maintenance.nix
    ./networking.nix
    ./access.nix
    ./storage.nix
    ./services/nginx.nix
    ./services/containers.nix
  ];
}
