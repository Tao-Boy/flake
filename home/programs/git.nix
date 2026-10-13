{ pkgsUnstable, ... }:
{
  programs.git = {
    enable = true;
    package = pkgsUnstable.git;
    ignores = [
      ".DS_Store"
      "*.swp"
      "*~"
      ".direnv/"
      ".devenv/"
    ];
    settings = {
      user.name = "tau";
      user.email = "taoboy03@qq.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
    };
  };
}
