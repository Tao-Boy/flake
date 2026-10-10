{ pkgsUnstable, ... }:
{
  programs = {
    # 日常 Bash 配置；别名直接写在 shellAliases 中。
    bash = {
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
    # programs 模块自行安装所选 unstable 包。
    fzf = {
      enable = true;
      package = pkgsUnstable.fzf;
      enableBashIntegration = true;
    };
    bat = {
      enable = true;
      package = pkgsUnstable.bat;
    };
    eza = {
      enable = true;
      package = pkgsUnstable.eza;
      enableBashIntegration = false;
    };
  };
}
