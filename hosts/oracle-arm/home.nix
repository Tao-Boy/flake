{
  # Optional CLI profile; the Oracle ARM system currently does not import it.
  imports = [
    ../../home/shell.nix
    ../../home/cli/utilities.nix
    ../../home/cli/diagnostics.nix
    ../../home/cli/network.nix
    ../../home/programs/git.nix
    ../../home/programs/neovim.nix
    ../../home/programs/tmux.nix
    ../../home/programs/npm.nix
  ];
}
