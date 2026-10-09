{ config, lib, ... }:
{
  config = lib.mkIf (config.fleet.enable && config.services.nginx.enable) {
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    services.nginx = {
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
    };
  };
}
