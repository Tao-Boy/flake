{
  # 防火墙使用 nftables；默认只开放 SSH 端口。
  networking.nftables.enable = true;

  # 不保存程序崩溃时的内存转储。
  systemd.coredump.settings.Coredump = {
    Storage = "none";
    ProcessSizeMax = 0;
  };

  # 内核网络参数：开启 SYN cookies，不接受、不发送 ICMP 重定向。
  boot.kernel.sysctl = {
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
  };
}
