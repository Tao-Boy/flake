{ ... }:
let
  # Check the whole disk with lsblk; prefer /dev/disk/by-id/... when available.
  disk = "/dev/vda";
in
{
  # GPT layout for both BIOS and UEFI. disko owns all filesystem definitions.
  disko.devices.disk.system = {
    type = "disk";
    device = disk;
    content = {
      type = "gpt";
      partitions = {
        bios = { size = "1M"; type = "EF02"; };
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
