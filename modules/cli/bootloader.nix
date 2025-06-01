{pkgs, ...}: {
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };
  boot.kernelParams = ["i915.enable_psr=0"];
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
