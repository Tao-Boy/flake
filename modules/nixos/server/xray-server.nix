{
  config,
  inputs,
  pkgs,
  ...
}:
{
  # The server configuration contains the Reality private key and is kept
  # encrypted at rest. sops-nix exposes it only at runtime.
  sops.secrets."server.json" = {
    sopsFile = ../../../secrets/server.json;
    format = "json";
    key = "";
    restartUnits = [ "xray.service" ];
  };

  services.xray = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.xray;
    settingsFile = config.sops.secrets."server.json".path;
  };

  # VLESS Reality listens directly on TCP port 2333.
  networking.firewall.allowedTCPPorts = [ 2333 ];
}
