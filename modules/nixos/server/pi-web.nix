{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "pi.nullcode.cc";
  host = "127.0.0.1";
  port = "30141";
  backend = "${host}:${port}";
  workspaceDir = "${config.users.users.tau.home}/pi-workspace";
  homeConfig = config.home-manager.users.tau;
  npm = homeConfig.programs.npm;
  npmBin = "${npm.settings.prefix}/bin";
in
{
  imports = [ ./nginx.nix ];

  sops.secrets."pi-web.env" = {
    sopsFile = ../../../secrets/server.env;
    format = "dotenv";
    key = "";
    mode = "0400";
    restartUnits = [ "pi-web.service" ];
  };

  systemd.tmpfiles.rules = [
    "d ${workspaceDir} 0700 tau users -"
  ];

  systemd.services.pi-web = {
    description = "Pi Web";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      HOME = workspaceDir;
      PATH = lib.mkForce (lib.concatStringsSep ":" [
        npmBin
        "${npm.package}/bin"
        "${homeConfig.home.profileDirectory}/bin"
        "/run/current-system/sw/bin"
      ]);
      PI_CODING_AGENT_DIR = "${workspaceDir}/.pi/agent";
      PI_WEB_SKIP_VERSION_CHECK = "1";
    };
    serviceConfig = {
      User = "tau";
      Group = "users";
      WorkingDirectory = workspaceDir;
      EnvironmentFile = config.sops.secrets."pi-web.env".path;
      NoNewPrivileges = true;
      # tau 手动用 npm 全局安装 pi-web 后即可启动。
      ExecCondition = "${pkgs.coreutils}/bin/test -f ${npmBin}/pi-web";
      # 域名白名单以站点配置为准，覆盖环境文件中的值。
      ExecStart = "${pkgs.coreutils}/bin/env PI_WEB_ALLOWED_HOSTS=${domain} ${npm.package}/bin/node ${npmBin}/pi-web --hostname ${host} --port ${port} --no-open";
      Restart = "on-failure";
      RestartSec = "5s";
    };
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
