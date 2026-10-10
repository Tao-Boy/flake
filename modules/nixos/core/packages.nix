{ pkgs, ... }:
{
  # OpenSSH、sudo、网络基础工具和 nixos-rebuild 由 NixOS 自带模块提供。
  # 此处只添加额外的系统诊断工具；用户软件放在 home/cli/。
  environment.systemPackages = [
    pkgs.dnsutils
    pkgs.pciutils
    pkgs.usbutils
  ];
}
