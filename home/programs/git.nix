{ pkgsUnstable, ... }:
{
  programs.git = {
    enable = true;
    package = pkgsUnstable.git;
    settings = {
      init.defaultBranch = "main";
      pull.ff = "only";
      fetch.prune = true;
    };
  };
}
