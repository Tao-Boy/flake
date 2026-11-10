{ config, ... }:
let
  domain = "ob.nullcode.cc";
  uid = toString config.users.users.tau.uid;
  gid = toString config.users.groups.users.gid;
in
{
  sops.secrets."ignis.htpasswd" = {
    sopsFile = ../../../secrets/ignis.htpasswd;
    format = "binary";
    owner = "nginx";
    group = "nginx";
    mode = "0400";
    restartUnits = [ "nginx.service" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/ignis 0750 tau users -"
    "d /var/lib/ignis/vaults 0750 tau users -"
    "d /var/lib/ignis/data 0750 tau users -"
    "d /var/lib/ignis/obsidian-app 0750 tau users -"
  ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers.ignis = {
      image = "docker.io/nobbe/ignis@sha256:2049be7dfbbee5ee9fa5c0ae56efd8555ec57f2ac3275448b1c4318b8af49bb5";
      ports = [ "127.0.0.1:30141:8080" ];
      environment = {
        PUID = uid;
        PGID = gid;
        WS_ORIGINS = "https://${domain}";
      };
      volumes = [
        "/var/lib/ignis/vaults:/vaults"
        "/var/lib/ignis/data:/app/data"
        "/var/lib/ignis/obsidian-app:/app/obsidian-app"
      ];
    };
  };

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
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts.${domain} = {
      enableACME = true;
      forceSSL = true;
      basicAuthFile = config.sops.secrets."ignis.htpasswd".path;

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
