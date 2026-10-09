{ config, lib, ... }:
let
  cfg = config.fleet;
  efi = cfg.bootMode != "bios";
  bios = cfg.bootMode != "uefi";
in
{
  config = lib.mkIf cfg.enable {
    disko.devices.disk.system = {
      type = "disk";
      device = cfg.diskDevice;
      content = {
        type = "gpt";
        partitions =
          lib.optionalAttrs bios {
            bios = { size = "1M"; type = "EF02"; };
          }
          // lib.optionalAttrs efi {
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
          }
          // {
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
        devices = if bios then [ cfg.diskDevice ] else [ "nodev" ];
        efiSupport = efi;
        efiInstallAsRemovable = efi;
        configurationLimit = 10;
      };
    };
  };
}
