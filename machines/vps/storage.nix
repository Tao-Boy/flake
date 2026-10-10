{
  imports = [
    ../../modules/disko.nix
    ../../modules/nixos/storage/ephemeral-root.nix
  ];
  # 需要明确核对的存储参数：安装将擦除此整盘，不能根据大小盲选。
  # 有稳定的 /dev/disk/by-id/... 时优先采用它。
  disko.devices.disk.system.device = "/dev/vda";
}
