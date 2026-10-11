{ lib, ... }:
{
  services = {
    chrony.enable = lib.mkDefault true;
    fstrim.enable = lib.mkDefault true;
  };
  zramSwap.enable = lib.mkDefault true;
  boot.loader.timeout = lib.mkDefault 3;
}
