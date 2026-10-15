{
  config,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
in
{
  systemd.user.services.pi-web = {
    Unit = {
      Description = "Pi Web";
      After = [ "network.target" ];
    };

    Service = {
      Type = "simple";

      ExecStart = "${pkgs.bash}/bin/bash -lic 'exec pi-web --no-open'";
      WorkingDirectory = homeDir;

      EnvironmentFile = "${homeDir}/.config/pi-web/server.env";

      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
