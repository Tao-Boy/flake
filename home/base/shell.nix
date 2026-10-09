{ pkgsUnstable, ... }:
{
  programs.bash = {
    enable = true;
    historyControl = [ "ignoreboth" ];
    historySize = 10000;
    historyFileSize = 20000;
    shellAliases = {
      ll = "eza -lah";
      gs = "git status --short --branch";
      v = "nvim";
      ports = "ss -tulpn";
      failed = "systemctl --failed";
    };
  };
  programs.fzf = {
    enable = true;
    package = pkgsUnstable.fzf;
    enableBashIntegration = true;
  };
  programs.bat = {
    enable = true;
    package = pkgsUnstable.bat;
  };
  programs.eza = {
    enable = true;
    package = pkgsUnstable.eza;
    enableBashIntegration = false;
  };
}
