{ pkgs, ... }:
{
  boot.loader = {
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };
  boot.kernelParams = [
    "i915.enable_psr=0"
    "iomem=relaxed"
  ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
