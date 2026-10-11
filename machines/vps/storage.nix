{
  imports = [ ../../modules/ephemeral-root.nix ];

  # 安装会擦除这块整盘，请用 lsblk 核对；有 /dev/disk/by-id/... 时优先使用它。
  disko.devices.disk.system.device = "/dev/vda";
  # /home 分区大小；/nix 使用剩余空间。只在首次安装分区时生效。
  disko.devices.disk.system.content.partitions.home.size = "4G";
}
