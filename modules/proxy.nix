{ config, lib, ... }:
let
  # 本地代理地址，端口与 secrets/xray.json 中的 inbounds 一致。
  http = "http://127.0.0.1:10809";
  socks = "socks5h://127.0.0.1:10808";
in
{
  sops.secrets."xray.json" = {
    sopsFile = ../secrets/xray.json;
    format = "json";
    key = "";
    restartUnits = [ "xray.service" ];
  };

  services.xray = {
    enable = true;
    settingsFile = config.sops.secrets."xray.json".path;
  };
  systemd.services.xray.wantedBy = lib.mkForce [ ];

  environment.shellAliases = {
    proxy-on = ''
      sudo systemctl start xray &&
      export http_proxy=${http} &&
      export https_proxy=${http} &&
      export all_proxy=${socks}
    '';

    proxy-off = ''
      unset http_proxy https_proxy all_proxy
      unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
      sudo systemctl stop xray
    '';

    proxy-status = "systemctl is-active xray";
  };
}
