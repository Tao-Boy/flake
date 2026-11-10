{
  services.chrony.enable = true; # 时间同步
  services.fstrim.enable = true; # 定期通知磁盘回收已删除的空间
  zramSwap.enable = true; # 使用压缩内存作为交换空间
  boot.loader.timeout = 3; # 启动菜单等待 3 秒
}
