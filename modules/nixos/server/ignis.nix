{ config, ... }:
let
  domain = "ob.nullcode.cc";
  backend = "127.0.0.1:30141";
  stateDir = "${config.users.users.tau.home}/ignis";
  uid = toString config.users.users.tau.uid;
  gid = toString config.users.groups.users.gid;
in
{
  imports = [
    ./nginx.nix
    ./podman.nix
  ];

  sops.secrets."ignis.htpasswd" = {
    sopsFile = ../../../secrets/ignis.htpasswd;
    format = "binary";
    owner = "nginx";
    group = "nginx";
    mode = "0400";
    restartUnits = [ "nginx.service" ];
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 tau users -"
    "d ${stateDir}/vaults 0750 tau users -"
    "d ${stateDir}/data 0750 tau users -"
    "d ${stateDir}/obsidian-app 0750 tau users -"
  ];

  virtualisation.oci-containers.containers.ignis = {
    image = "docker.io/nobbe/ignis:latest";
    pull = "always";
    ports = [ "${backend}:8080" ];
    environment = {
      PUID = uid;
      PGID = gid;
      WS_ORIGINS = "https://${domain}";
    };
    volumes = [
      "${stateDir}/vaults:/vaults"
      "${stateDir}/data:/app/data"
      "${stateDir}/obsidian-app:/app/obsidian-app"
    ];
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    basicAuthFile = config.sops.secrets."ignis.htpasswd".path;

    locations."/" = {
      proxyPass = "http://${backend}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_buffering off;
      '';
    };
  };
}
