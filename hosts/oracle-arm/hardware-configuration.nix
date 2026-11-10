{
  lib,
  modulesPath,
  ...
}:
{
  # This is a template for an Oracle Cloud Ampere A1 VM. Generate a fresh
  # hardware file on the instance when possible and review the result before
  # installing.
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "nvme"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  networking.useDHCP = lib.mkDefault true;
}
