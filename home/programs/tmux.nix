{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    clock24 = true;
    baseIndex = 1;
    historyLimit = 10000;
    escapeTime = 10;
  };
}
