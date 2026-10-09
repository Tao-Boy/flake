{ ... }:
{
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
