{ pkgs, pkgsUnstable, ... }:
{
  # 每行一个包，前缀直接表明来源；添加或删除一行即可调整软件。
  home.packages = [
    # 稳定源：日常工具与诊断软件。
    pkgs.curl
    pkgs.wget
    pkgs.jq
    pkgs.yq-go
    pkgs.tree
    pkgs.less
    pkgs.rsync
    pkgs.unzip
    pkgs.zip
    pkgs.gnutar
    pkgs.gzip
    pkgs.xz
    pkgs.zstd
    pkgs.htop
    pkgs.ncdu
    pkgs.lsof
    pkgs.file
    pkgs.strace
    pkgs.sysstat
    pkgs.mtr
    pkgs.tcpdump
    pkgs.nmap
    pkgs.socat
    pkgs.ethtool

    # unstable 源：精选的新版本终端工具。
    pkgsUnstable.ripgrep
    pkgsUnstable.fd
    pkgsUnstable.btop
  ];

  # programs.* 启用后会安装软件，无需再加到上面的 home.packages。
  programs.git = {
    enable = true;
    package = pkgsUnstable.git;
    settings = {
      init.defaultBranch = "main";
      pull.ff = "only";
      fetch.prune = true;
    };
    # 作者姓名和邮箱可在 home/hosts/vps.nix 中设置。
  };

  programs.neovim = {
    enable = true;
    package = pkgsUnstable.neovim-unwrapped;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # 按需启用语言 provider，默认保持编辑器精简。
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
  };

  programs.tmux = {
    enable = true;
    # 未指定 package 时，Home Manager 使用稳定源中的默认软件包。
    terminal = "tmux-256color";
    clock24 = true;
    baseIndex = 1;
    historyLimit = 10000;
    escapeTime = 10;
  };
}
