{
  imports = [
    ../../modules/nixos/base/users.nix # 用户与 SSH 公钥
    ../../modules/nixos/base/core.nix # Nix 设置与旧版本清理
    ../../modules/nixos/base/networking.nix # DHCP 网络
    ../../modules/nixos/base/security.nix # 防火墙与内核网络参数
    ../../modules/nixos/server/sops.nix # 解密 secrets/ 中的加密文件
    ../../modules/nixos/server/ssh.nix # SSH 与 fail2ban
    ../../modules/nixos/server/xray-server.nix # Xray Reality 服务端
    ../../modules/nixos/server/ignis.nix # Podman Ignis 与 HTTPS 入口
    ./hardware-configuration.nix # Oracle Cloud ARM 硬件
    ./disko-fs.nix # 磁盘分区
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  networking.hostName = "oracle-arm";
  time.timeZone = "UTC";

  system.stateVersion = "26.05";
}
