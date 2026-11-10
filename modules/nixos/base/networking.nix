{
  networking.useNetworkd = true;
  networking.useDHCP = true;

  # BBR 拥塞控制配合 fq 队列，改善高延迟、易丢包线路（如跨境代理）的吞吐。
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
}
