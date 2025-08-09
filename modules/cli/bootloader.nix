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
  boot.kernelParams = ["i915.enable_psr=0" "iomem=relaxed"];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  programs.nix-ld.enable = true;
}
