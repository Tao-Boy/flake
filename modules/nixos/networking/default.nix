{ config, lib, ... }:
{
  # NixOS 自动生成匹配物理以太网接口的 DHCP 规则，不写死接口名。
  # 地址、路由和 DNS 由 DHCP / IPv6 RA 提供；静态网络才在机器中覆盖。
  networking.useNetworkd = lib.mkDefault true;
  networking.useDHCP = lib.mkDefault true;
  services.resolved.enable = lib.mkDefault true;

  # 根目录易失时也使用稳定的 DHCP 身份；不重复声明匹配规则。
  systemd.network.networks."99-ethernet-default-dhcp" =
    lib.mkIf (config.networking.useNetworkd && config.networking.useDHCP)
      {
        dhcpV4Config.ClientIdentifier = "mac";
        dhcpV6Config.DUIDType = "link-layer";
        networkConfig.IPv6AcceptRA = true;
        linkConfig.RequiredForOnline = "routable";
      };
}
