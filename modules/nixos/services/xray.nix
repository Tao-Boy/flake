{
  config,
  lib,
  pkgs,
  ...
}:
let
  environment = import ../../../proxy/environment.nix { inherit lib; };
in
{
  imports = [ ../../sops.nix ];
  sops.secrets."xray.json" = {
    format = "json";
    key = ""; # 解密整份原生 Xray JSON，不提取字段或生成模板。
    restartUnits = [ "xray.service" ];
  };

  systemd.services.xray = {
    description = "Xray proxy";
    wantedBy = [ "multi-user.target" ];
    after = [
      "sops-install-secrets.service"
      "network-online.target"
    ];
    requires = [ "sops-install-secrets.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      DynamicUser = true;
      LoadCredential = "config.json:${config.sops.secrets."xray.json".path}";
      ExecStart = "${pkgs.xray}/bin/xray run -config %d/config.json";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
    };
  };
  systemd.services.nix-daemon = {
    after = [ "xray.service" ];
    inherit environment;
  };
  environment.systemPackages = [
    (pkgs.callPackage ../../../proxy { })
    (pkgs.callPackage ../../../proxy/setup.nix { })
  ];
}
