{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  # 通用 KVM/QEMU 虚拟机驱动；请按实际 VPS 硬件核对。
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "ahci"
    "xhci_pci"
    "sd_mod"
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "nvme"
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # 挂载和分区由 disk-config.nix 中的 disko 配置生成。
  # 若采用 nixos-generate-config 的输出，先去除重复的挂载与引导器配置。
}
