{ lib, ... }:
{
  imports = [
    ./shell
    ./cli
    ./programs/git.nix
    ./programs/neovim.nix
    ./programs/tmux.nix
  ];

  home.stateVersion = lib.mkDefault "26.05";
}
