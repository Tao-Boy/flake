{ config, ... }:
let
  domain = "sync.nullcode.cc";
  backend = "127.0.0.1:9000";
  stateDir = "${config.users.users.tau.home}/fast-note-sync";
  uid = toString config.users.users.tau.uid;
  gid = toString config.users.groups.users.gid;
in
{
  imports = [
    ./nginx.nix
    ./podman.nix
  ];

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0700 tau users -"
    "d ${stateDir}/config 0700 tau users -"
    "d ${stateDir}/storage 0700 tau users -"
  ];

  virtualisation.oci-containers.containers.fast-note-sync = {
    image = "docker.io/haierkeys/fast-note-sync-service:latest";
    pull = "always";
    ports = [ "${backend}:9000" ];
    user = "${uid}:${gid}";
    volumes = [
      "${stateDir}/config:/fast-note-sync/config"
      "${stateDir}/storage:/fast-note-sync/storage"
    ];
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    extraConfig = ''
      client_max_body_size 128m;
    '';

    locations."/" = {
      proxyPass = "http://${backend}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_buffering off;
        proxy_request_buffering off;
      '';
    };
  };
}
