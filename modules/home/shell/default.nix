{ pkgsUnstable, ... }:
{
  # 日常 Bash 配置；别名直接写在 shellAliases 中。
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
  # 这些 programs 模块会自行安装所选 unstable 软件包。
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
