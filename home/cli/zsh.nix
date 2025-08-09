{ ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
