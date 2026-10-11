{
  # 本机选择启用的用户模块；软件配置统一在 home/ 中维护。
  imports = [
    # Shell 与常用工具。
    ../../home/shell.nix
    ../../home/cli/utilities.nix
    ../../home/cli/diagnostics.nix
    ../../home/cli/network.nix
    # 单独配置的程序。
    ../../home/programs/git.nix
    ../../home/programs/neovim.nix
    ../../home/programs/tmux.nix
  ];
}
