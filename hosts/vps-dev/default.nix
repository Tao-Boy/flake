{
  imports = [
    ../../modules/nixos/server # 共用系统底座、SOPS 与 SSH
    ../../modules/nixos/base/maintenance.nix # 时间同步、zram 等
    ../../modules/nixos/base/home-manager.nix # 用户开发环境
    ../../modules/nixos/server/xray-client.nix # 按需启用代理
    ./hardware-configuration.nix
    ./disko-fs.nix
  ];

  home-manager.users.tau = ./home.nix;
  system.stateVersion = "26.05";
}
