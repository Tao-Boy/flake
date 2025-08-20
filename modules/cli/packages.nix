{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    zstd
    unzip
    gcc
    ripgrep
    gnumake

    emacs-nox
  ];
  environment.variables.EDITOR = "nvim";
}
