{
  # 本机选择启用的用户模块；软件配置统一在 home/ 中维护。
  imports = [
    ../../home
    ../../home/shell
    ../../home/cli/utilities.nix
    ../../home/cli/diagnostics.nix
    ../../home/cli/network.nix
    ../../home/programs/git.nix
    ../../home/programs/neovim.nix
    ../../home/programs/tmux.nix
  ];
}
