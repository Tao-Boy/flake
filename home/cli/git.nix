{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f ${config.home.homeDirectory}/.gitconfig
  '';

  programs.git = {
    enable = true;

    userName = username;
    userEmail = "taoboy03@qq.com";

    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };
}
