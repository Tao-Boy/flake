{
  imports = [ ../../modules/nixos/storage/ephemeral-root.nix ];
  # 需要明确核对的存储参数：安装将擦除此整盘，不能根据大小盲选。
  # 有稳定的 /dev/disk/by-id/... 时优先采用它。
  disko.devices.disk.system.device = "/dev/vda";
  # /home 默认 4 GiB，/nix 使用剩余空间；需要时覆盖共享默认值。
  # disko.devices.disk.system.content.partitions.home.size = "8G";
}
