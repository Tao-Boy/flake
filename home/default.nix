{ lib, ... }:
{
  imports = [
    ./packages.nix
    ./programs/shell.nix
    ./programs/git.nix
    ./programs/neovim.nix
    ./programs/tmux.nix
  ];

  # Username/home directory come from the NixOS account, including renames.
  # Preserve this value after first deploying Home Manager, independently of NixOS.
  home.stateVersion = lib.mkDefault "26.05";
}
