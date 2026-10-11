{
  config,
  lib,
  pkgs,
  ...
}:
let
  proxy = import ../../../proxy/settings.nix { inherit lib; };
  secrets = lib.genAttrs proxy.secretNames (name: config.sops.placeholder."xray/${name}");
in
{
  imports = [ ../../sops.nix ];
  sops.secrets = lib.genAttrs (map (name: "xray/${name}") proxy.secretNames) (_: { });
  sops.templates.xray = {
    content = builtins.toJSON (proxy.settings secrets);
    restartUnits = [ "xray.service" ];
  };
  services.xray = {
    enable = true;
    settingsFile = config.sops.templates.xray.path;
  };
  systemd.services.xray = {
    after = [
      "sops-install-secrets.service"
      "network-online.target"
    ];
    requires = [ "sops-install-secrets.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
  systemd.services.nix-daemon = {
    after = [ "xray.service" ];
    environment = proxy.environment;
  };
  environment.systemPackages = [ (pkgs.callPackage ../../../proxy { }) ];
}
