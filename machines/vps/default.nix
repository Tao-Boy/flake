{ config, ... }:
{
  imports = [
    # 系统基础与安全。
    ../../modules/nixos/base.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/security/ssh.nix
    ../../modules/nixos/security/hardening.nix
    # 本机需要的服务和用户环境。
    ../../modules/nixos/services/maintenance.nix
    ../../modules/nixos/services/proxy.nix
    ../../modules/nixos/home-manager.nix
    # 本机硬件与磁盘；硬件文件由用户维护。
    ./hardware-configuration.nix
    ./storage.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "vps";
  time.timeZone = "UTC";
  services.qemuGuest.enable = true;

  home-manager.users.${config.local.admin.name} = ./home.nix;
  local.proxy.configFile = ../../secrets/xray.json;

  # 保留首次安装时的兼容版本，不随输入更新改变。
  system.stateVersion = "26.05";
}
