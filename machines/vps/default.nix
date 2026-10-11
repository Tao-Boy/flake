{ users, ... }:
{
  imports = [
    ../../modules/nixos/base.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/security/ssh.nix
    ../../modules/nixos/security/hardening.nix
    ../../modules/nixos/services/maintenance.nix
    ../../modules/home-manager.nix
    ./hardware-configuration.nix
    ./storage.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  home-manager.users.${users.username} = ./home.nix;
  services.qemuGuest.enable = true;
  time.timeZone = "UTC";
  # 保留首次安装时的兼容版本，不随输入更新改变。
  system.stateVersion = "26.05";
}
