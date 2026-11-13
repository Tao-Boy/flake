{
  imports = [
    ../../modules/nixos/server # 共用系统底座、SOPS 与 SSH
    ../../modules/nixos/base/maintenance.nix # 时间同步、zram 等
    ../../modules/nixos/base/home-manager.nix # 用户软件
    ../../modules/nixos/server/xray-client.nix # Xray 客户端与 proxy-on / proxy-off
    ../../modules/nixos/server/pi-web.nix # Podman pi-web 与 HTTPS 入口
    ../../modules/nixos/server/fast-note-sync.nix # 笔记同步与 sync.nullcode.cc
    ./hardware-configuration.nix # 硬件
    ./disko-fs.nix # 磁盘分区
  ];

  home-manager.users.tau = ./home.nix;
  system.stateVersion = "26.05";
}
