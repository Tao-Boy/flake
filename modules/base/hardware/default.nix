{hostName, ...}:{

 imports = [
   ./${hostName}.nix
 ];
  
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  boot.kernelParams = [
    "i915.enable_psr=0"
  ];
}
