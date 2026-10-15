{ config, pkgs, ... }:
{
  programs.npm = {
    enable = true;
    package = pkgs.nodejs;
    settings = {
      prefix = "${config.home.homeDirectory}/.npm";
    };
  };

  home.sessionPath = [
    "${config.programs.npm.settings.prefix}/bin"
  ];
}
