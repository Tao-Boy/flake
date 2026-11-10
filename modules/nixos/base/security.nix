{
  networking.nftables.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.tcp_syncookies" = 1;
    # 不接受 ICMP 重定向与源路由，本机也不发送重定向。
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    # 普通用户不能读取内核日志与内核地址。
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
  };
}
