let
  # 只在这里修改目标整盘路径，disko 和 GRUB 会共用它。
  # 用 lsblk 核对磁盘；可用时优先采用稳定的 /dev/disk/by-id/...。
  disk = "/dev/vda";
in
{
  # 根目录在内存中，每次重启清空；50% 是上限，不会提前占用内存。
  disko.devices.nodev."/" = {
    fsType = "tmpfs";
    mountOptions = [ "size=50%" "mode=755" ];
  };

  # GPT 同时支持 BIOS / UEFI；/boot、/nix 和 /home 保存在磁盘上。
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
        data = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            # 两个子卷共享剩余磁盘空间，不需要分别指定大小。
            subvolumes = {
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };

  # 只补充启动顺序；设备、类型和挂载选项仍由 disko 生成。
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/home".neededForBoot = true;

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
