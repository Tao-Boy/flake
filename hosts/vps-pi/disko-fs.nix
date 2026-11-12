{
  imports = [ ../../modules/nixos/base/disko.nix ];

  # The installation command formats this entire disk. Verify it first.
  disko.devices.disk.system = {
    device = "/dev/vda";
    content.partitions.bios = {
      size = "1M";
      type = "EF02";
    };
  };

  # Show boot output in both the display and the provider's serial console.
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];
}
