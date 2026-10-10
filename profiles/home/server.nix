{ lib, ... }:
{
  imports = [
    ../../modules/home/shell/default.nix
    ../../modules/home/cli/default.nix
    ../../modules/home/programs/git.nix
    ../../modules/home/programs/neovim.nix
    ../../modules/home/programs/tmux.nix
  ];
  home.stateVersion = lib.mkDefault "26.05";
}
