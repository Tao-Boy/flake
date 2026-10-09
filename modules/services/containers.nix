{ config, lib, ... }:
{
  config = lib.mkIf (config.fleet.enable && config.fleet.containers.enable) {
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    # No container engine TCP API, application ports or containers enabled here.
  };
}
