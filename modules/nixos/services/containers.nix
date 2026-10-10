{
  # 在主机 imports 中加入本文件，就会启用 Podman。
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
}
