{
  imports = [
    ../../modules/nixos/base/users.nix # 用户与 SSH 公钥
    ../../modules/nixos/base/core.nix # Nix 设置与旧版本清理
    ../../modules/nixos/base/networking.nix # DHCP 网络
    ../../modules/nixos/base/security.nix # 防火墙与内核网络参数
    ../../modules/nixos/base/maintenance.nix # 时间同步、zram 等
    ../../modules/nixos/base/home-manager.nix # 用户软件
    ../../modules/nixos/server/sops.nix # 解密 secrets/ 中的加密文件
    ../../modules/nixos/server/ssh.nix # SSH 与 fail2ban
    ../../modules/nixos/server/xray-client.nix # Xray 客户端与 proxy-on / proxy-off
    ../../modules/nixos/server/nginx.nix # Nginx 反向代理 pi-web 与 HTTPS 证书
    ./hardware-configuration.nix # 硬件
    ./disko-fs.nix # 磁盘分区
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "vps";
  time.timeZone = "UTC";

  home-manager.users.tau = ./home.nix;
  system.stateVersion = "26.05";
}
