{
  config,
  pkgs,
  inputs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    inputs.nixos-hardware.nixosModules.google-pixelbook
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vaapiIntel
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  boot.initrd.availableKernelModules = ["xhci_pci" "dwc3_pci" "usb_storage" "sd_mod" "sdhci_pci"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
