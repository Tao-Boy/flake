{
  # Oracle ARM uses the same CLI and user services as the VPS profile.
  imports = [
    ../../home/shell.nix
    ../../home/cli/utilities.nix
    ../../home/cli/diagnostics.nix
    ../../home/cli/network.nix
    ../../home/programs/git.nix
    ../../home/programs/neovim.nix
    ../../home/programs/tmux.nix
    ../../home/programs/npm.nix
    ../../home/programs/pi.nix
  ];
}
