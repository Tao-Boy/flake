{
  lib,
  modulesPath,
  ...
}:
{
  # Generic KVM/QEMU template; regenerate on the target when needed.
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
    "virtio_blk"
  ];

  networking.useDHCP = lib.mkDefault true;
}
