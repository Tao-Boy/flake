{ ... }:
let
  domain = "pi.nullcode.cc";
in
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "taoboy03@qq.com";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts.${domain} = {
      enableACME = true;
      forceSSL = true;
      extraConfig = ''
        client_max_body_size 128m;
        access_log off;
      '';

      locations."/" = {
        proxyPass = "http://127.0.0.1:30141";

        proxyWebsockets = true;

        extraConfig = ''
          proxy_read_timeout 3600s;
          proxy_send_timeout 3600s;
          proxy_buffering off;
        '';
      };
    };
  };
}
