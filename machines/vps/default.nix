{
  imports = [
    ../../user.nix # 唯一的用户与 SSH 公钥
    ../../modules/base.nix # Nix 设置与旧版本清理
    ../../modules/networking.nix # DHCP 网络
    ../../modules/sops.nix # 解密 secrets/ 中的加密文件
    ../../modules/ssh.nix # SSH、加密的主机密钥与 fail2ban
    ../../modules/hardening.nix # 防火墙与内核网络参数
    ../../modules/maintenance.nix # 时间同步、zram 等
    ../../modules/proxy.nix # Xray 代理与 proxy-on / proxy-off
    ../../modules/home-manager.nix # 用户软件
    ../../modules/nginx.nix # Nginx 反向代理 pi-web 与 HTTPS 证书
    ./hardware-configuration.nix # 硬件
    ./storage.nix # 磁盘分区
    ../../modules/impermanence.nix # 重启后需要保留的文件
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "vps";
  time.timeZone = "UTC";

  home-manager.users.tau = ./home.nix;
  system.stateVersion = "26.05";
}
