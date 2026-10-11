{ config, lib, ... }:
{
  # 使用 systemd-networkd：NixOS 自动为以太网接口启用 DHCP，不写死接口名。
  # 地址、路由和 DNS 由服务商的 DHCP / IPv6 RA 提供。
  networking.useNetworkd = true;
  services.resolved.enable = true;

  # 根目录每次重启都会清空，因此用网卡 MAC 作为 DHCP 身份，保证地址稳定。
  # "99-ethernet-default-dhcp" 是 NixOS 自动生成的规则，这里只补充设置。
  # 只在使用 DHCP 时生效；服务商要求静态地址时，见 docs/customization.md。
  systemd.network.networks."99-ethernet-default-dhcp" = lib.mkIf config.networking.useDHCP {
    dhcpV4Config.ClientIdentifier = "mac";
    dhcpV6Config.DUIDType = "link-layer";
    networkConfig.IPv6AcceptRA = true;
    linkConfig.RequiredForOnline = "routable";
  };
}
