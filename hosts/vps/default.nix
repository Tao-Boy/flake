{ ... }:
{
  imports = [
    ../../modules/base
    ../../modules/nixos/server.nix
    ./hardware-configuration.nix
    ./disk-config.nix
    # ../../modules/nixos/nginx.nix
    # ../../modules/nixos/containers.nix
  ];

  time.timeZone = "UTC";
  # Keep the value set when this host was first installed.
  system.stateVersion = "26.05";

  # Host network configuration uses native NixOS options.
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
  systemd.network.networks."10-uplink" = {
    matchConfig.Name = "en* eth*";
    networkConfig = {
      DHCP = "yes";
      IPv6AcceptRA = true;
    };
    linkConfig.RequiredForOnline = "routable";
  };

  # To change the installed SSH port: services.openssh.ports = [ 2222 ];
  # Set username and public keys in ../../vars/default.nix.
}
