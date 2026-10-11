{
  # 这台机器使用的配置；不需要的功能删掉对应一行即可。
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
    ./hardware-configuration.nix # 硬件
    ./storage.nix # 磁盘分区
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "vps";
  time.timeZone = "UTC";
  services.qemuGuest.enable = true;

  # 用户 tau 的软件在 home.nix 中选择。
  home-manager.users.tau = ./home.nix;

  # 首次安装时的系统版本，升级软件时保持不变。
  system.stateVersion = "26.05";
}
