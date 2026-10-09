{
  # 按需在列表中加入模块路径；可选服务默认保持注释。
  imports = [
    ../../modules/base/default.nix
    ../../modules/nixos/server.nix
    ./hardware-configuration.nix
    ./disk-config.nix
    # ../../modules/nixos/nginx.nix
    # ../../modules/nixos/containers.nix
  ];

  time.timeZone = "UTC";
  # 保留主机首次安装时的值，不随软件升级修改。
  system.stateVersion = "26.05";

  # 网络直接使用 NixOS 原生选项；静态地址示例见 docs/customization.md。
  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];
  systemd.network.networks."10-uplink" = {
    matchConfig.Name = "en* eth*";
    networkConfig = {
      DHCP = "yes";
      IPv6AcceptRA = true;
    };
    # /etc/machine-id 每次启动重新生成；DHCP 身份使用网卡 MAC。
    dhcpV4Config.ClientIdentifier = "mac";
    dhcpV6Config.DUIDType = "link-layer";
    linkConfig.RequiredForOnline = "routable";
  };

  # 修改安装后的 SSH 端口，取消下面这一行的注释即可：
  # services.openssh.ports = [ 2222 ];
  # 用户名和公钥统一在 ../../vars/default.nix 设置。
}
