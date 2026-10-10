{ lib, ... }:
{
  services = {
    chrony.enable = lib.mkDefault true;
    qemuGuest.enable = lib.mkDefault true;
    fstrim.enable = lib.mkDefault true;
  };
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = "zstd";
    memoryPercent = lib.mkDefault 50;
  };
  boot.loader.timeout = lib.mkDefault 3;
}
