{ config, lib, ... }:
let cfg = config.fleet;
in
{
  config = lib.mkIf cfg.enable {
    networking = {
      useDHCP = false;
      useNetworkd = true;
      nameservers = cfg.network.dns;
      nftables.enable = true;
      firewall = {
        enable = true;
        allowedTCPPorts = [ cfg.access.sshPort ];
        allowPing = true;
      };
    };
    services.resolved.enable = true;
    systemd.network = {
      enable = true;
      networks."10-uplink" = {
        matchConfig.Name = cfg.network.interface;
        networkConfig = {
          DHCP = if cfg.network.dhcp then "yes" else "no";
          IPv6AcceptRA = cfg.network.acceptRA;
        };
        address = cfg.network.addresses;
        routes =
          lib.optional (cfg.network.gateway4 != null) {
            routeConfig = { Gateway = cfg.network.gateway4; GatewayOnLink = true; };
          }
          ++ lib.optional (cfg.network.gateway6 != null) {
            routeConfig = { Gateway = cfg.network.gateway6; GatewayOnLink = true; };
          };
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
