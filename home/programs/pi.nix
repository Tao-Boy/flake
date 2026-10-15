{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
in
{
  # pi 与 pi-web 由用户自行用 npm 全局安装（npm i -g，位于 ~/.npm/bin），这里只声明服务。
  # 用户服务默认在登录后才启动；user.nix 中的 linger 让它开机运行。
  systemd.user.services.pi-web = {
    Unit.Description = "Pi Web";

    Service = {
      Type = "simple";

      # 显式设置 PATH，不再依赖交互式登录 Shell（bash -lic）：
      # npm 全局命令、Home Manager 软件、nix profile、sudo 等包装器、系统软件。
      Environment = [
        "PATH=${
          lib.concatStringsSep ":" [
            "${config.programs.npm.settings.prefix}/bin"
            "${config.home.profileDirectory}/bin"
            "${homeDir}/.nix-profile/bin"
            "/run/wrappers/bin"
            "/run/current-system/sw/bin"
          ]
        }"
      ];
      ExecStart = "${pkgs.bash}/bin/bash -c 'exec pi-web --no-open'";
      WorkingDirectory = homeDir;

      EnvironmentFile = "${homeDir}/.config/pi-web/server.env";

      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
