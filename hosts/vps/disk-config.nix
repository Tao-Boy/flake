let
  # 只在这里修改目标整盘路径，disko 和 GRUB 会共用它。
  # 用 lsblk 核对磁盘；可用时优先采用稳定的 /dev/disk/by-id/...。
  disk = "/dev/vda";
in
{
  # GPT 分区同时支持 BIOS / UEFI；文件系统挂载由 disko 生成。
  disko.devices.disk.system = {
    type = "disk";
    device = disk;
    content = {
      type = "gpt";
      partitions = {
        bios = {
          size = "1M";
          type = "EF02";
        };
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [ "defaults" "noatime" ];
          };
        };
      };
    };
  };
  boot.loader = {
    efi.canTouchEfiVariables = false;
    grub = {
      enable = true;
      devices = [ disk ];
      efiSupport = true;
      efiInstallAsRemovable = true;
      configurationLimit = 10;
    };
  };
}
