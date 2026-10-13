{
  # 在主机 imports 中加入本文件，就会启用 Nginx 并开放 80/443。
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
  };
}
