{ pkgs, ... }:
{
  # 系统维护工具直接提供给所有用户，不依赖 Home Manager。
  environment.systemPackages = [
    pkgs.git
    pkgs.curl
    pkgs.wget
    pkgs.rsync
    pkgs.jq
    pkgs.ripgrep
    pkgs.fd
    pkgs.file
    pkgs.tree
    pkgs.less
    pkgs.zip
    pkgs.unzip
    pkgs.tmux
    pkgs.htop
    pkgs.lsof
    pkgs.dnsutils
    pkgs.sops
    pkgs.age
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
