{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Local proxy endpoints from the client configuration.
  http = "http://127.0.0.1:10809";
  socks = "socks5h://127.0.0.1:10808";
  noProxy = "localhost,127.0.0.1,::1";
in
{
  # The client configuration is encrypted at rest and only appears under
  # /run/secrets after sops-nix activates the system.
  sops.secrets."client.json" = {
    sopsFile = ../../../secrets/client.json;
    format = "json";
    key = "";
    restartUnits = [ "xray.service" ];
  };

  services.xray = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.xray;
    settingsFile = config.sops.secrets."client.json".path;
  };

  # A client is started on demand through proxy-on.
  systemd.services.xray.wantedBy = lib.mkForce [ ];

  environment.shellAliases = {
    proxy-on = ''
      sudo systemctl start xray &&
      export http_proxy=${http} &&
      export https_proxy=${http} &&
      export all_proxy=${socks} &&
      export no_proxy=${noProxy}
    '';

    proxy-off = ''
      unset http_proxy https_proxy all_proxy no_proxy
      unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
      sudo systemctl stop xray
    '';

    proxy-status = "systemctl is-active xray";
  };
}
