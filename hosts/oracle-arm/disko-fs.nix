{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];

  # Oracle Cloud commonly exposes the boot volume as /dev/sda. Verify the
  # actual device with `lsblk` before running the installer.
  disko.devices.disk.system = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
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
            mountOptions = [ "noatime" ];
          };
        };
      };
    };
  };

  services.journald.extraConfig = "SystemMaxUse=64M";

  # Oracle Cloud instances boot through UEFI. Install GRUB to the removable
  # EFI path because firmware variable writes are unavailable to the guest.
  boot.loader = {
    efi.canTouchEfiVariables = false;
    grub = {
      enable = true;
      devices = [ "nodev" ];
      efiSupport = true;
      efiInstallAsRemovable = true;
      configurationLimit = 10;
    };
  };
}
