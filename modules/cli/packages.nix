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
    alejandra
    dmidecode
    mutagen
  ];
  environment.variables.EDITOR = "nvim";
}
