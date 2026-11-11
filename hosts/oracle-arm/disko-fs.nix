{
  imports = [ ../../modules/nixos/base/disko.nix ];

  # Oracle Cloud commonly exposes the boot volume as /dev/sda. Verify with lsblk.
  disko.devices.disk.system.device = "/dev/sda";

  # Oracle Cloud instances use UEFI without installing GRUB to a BIOS device.
  boot.loader.grub.devices = [ "nodev" ];
}
