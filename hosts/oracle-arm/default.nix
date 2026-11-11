{
  imports = [
    ../../modules/nixos/server # 共用系统底座、SOPS 与 SSH
    ../../modules/nixos/base/cli.nix # Git、编辑器与系统维护工具
    ../../modules/nixos/server/xray-server.nix # Xray Reality 服务端
    ../../modules/nixos/server/ignis.nix # Podman Ignis 与 HTTPS 入口
    ./hardware-configuration.nix # Oracle Cloud ARM 硬件
    ./disko-fs.nix # 磁盘分区
  ];

  system.stateVersion = "26.05";
}
