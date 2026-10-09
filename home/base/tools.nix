{ pkgs, pkgsUnstable, ... }:
{
  home.packages =
    (with pkgs; [
      # Stable user utilities and optional diagnostics.
      curl wget jq yq-go tree less rsync
      unzip zip gnutar gzip xz zstd
      htop ncdu lsof file strace sysstat
      mtr tcpdump nmap socat ethtool
    ])
    ++ (with pkgsUnstable; [
      # Selected frequently updated terminal tools.
      ripgrep fd btop
    ]);

  # Applications configured through programs.* are installed by those modules;
  # keep them out of home.packages to avoid duplicate stable/unstable binaries.

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

  programs.neovim = {
    enable = true;
    package = pkgsUnstable.neovim-unwrapped;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # Keep the VPS editor small; enable language providers when needed.
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
  };

  programs.tmux = {
    enable = true;
    # Stable by default, unlike the selected tools above.
    terminal = "tmux-256color";
    clock24 = true;
    baseIndex = 1;
    historyLimit = 10000;
    escapeTime = 10;
  };
}
