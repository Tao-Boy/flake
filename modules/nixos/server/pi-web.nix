{ config, ... }:
let
  domain = "pi.nullcode.cc";
  backend = "127.0.0.1:30141";
  workspaceDir = "${config.users.users.tau.home}/pi-workspace";
  uid = toString config.users.users.tau.uid;
  gid = toString config.users.groups.users.gid;
in
{
  imports = [
    ./nginx.nix
    ./podman.nix
  ];

  sops.secrets."pi-web.env" = {
    sopsFile = ../../../secrets/server.env;
    format = "dotenv";
    key = "";
    mode = "0400";
    restartUnits = [ "podman-pi-web.service" ];
  };

  systemd.tmpfiles.rules = [
    "d ${workspaceDir} 0700 tau users -"
  ];

  virtualisation.oci-containers.containers.pi-web = {
    image = "ghcr.io/agegr/pi-web:latest";
    pull = "always";
    ports = [ "${backend}:30141" ];
    user = "${uid}:${gid}";
    workdir = workspaceDir;
    environment = {
      HOME = workspaceDir;
      PI_CODING_AGENT_DIR = "${workspaceDir}/.pi/agent";
      PI_WEB_ALLOWED_HOSTS = domain;
      PI_WEB_SKIP_VERSION_CHECK = "1";
    };
    environmentFiles = [ config.sops.secrets."pi-web.env".path ];
    volumes = [ "${workspaceDir}:${workspaceDir}" ];
    # 入口不依赖容器工作目录。
    cmd = [
      "node"
      "/app/bin/pi-web.js"
      "--hostname"
      "0.0.0.0"
      "--port"
      "30141"
      "--no-open"
    ];
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    extraConfig = ''
      client_max_body_size 128m;
      access_log off;
    '';

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
