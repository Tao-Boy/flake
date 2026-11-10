{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];

  # The VPS uses the whole disk for a persistent ext4 root filesystem.
  # The installation command formats the configured device, so verify it first.
  disko.devices.disk.system = {
    type = "disk";
    device = "/dev/vda";
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
            mountOptions = [ "noatime" ];
          };
        };
      };
    };
  };

  # Keep the persistent journal bounded on the root filesystem.
  services.journald.extraConfig = "SystemMaxUse=64M";

  # Show boot output in both the display and the provider's serial console.
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];

  # GRUB supports both BIOS and UEFI boot and keeps the newest ten generations.
  boot.loader = {
    efi.canTouchEfiVariables = false;
    grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      configurationLimit = 10;
    };
  };
}
