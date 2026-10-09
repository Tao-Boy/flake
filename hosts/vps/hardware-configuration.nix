{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  # Generic KVM/QEMU guest defaults. Verify on your VPS; not suitable for OpenVZ/LXC.
  boot.initrd.availableKernelModules = [
    "ata_piix" "ahci" "xhci_pci" "sd_mod"
    "virtio_pci" "virtio_blk" "virtio_scsi" "nvme"
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # disko is the only source of fileSystems and swapDevices.
  # If replacing this file with nixos-generate-config output, remove its
  # fileSystems/swapDevices and conflicting bootloader definitions first.
}
