{ ... }:
{
  # Import this module only on hosts running Nginx.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
  };
}
