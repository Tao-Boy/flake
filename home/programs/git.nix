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
    # Set your author name/email in a host-specific user override.
  };
}
