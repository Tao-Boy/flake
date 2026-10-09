{ config, lib, ... }:
{
  config = lib.mkIf config.fleet.enable {
    zramSwap = {
      enable = lib.mkDefault true;
      algorithm = "zstd";
      memoryPercent = lib.mkDefault 50;
    };
    services.fstrim.enable = lib.mkDefault true;

    services.journald.extraConfig = ''
      Storage=persistent
      SystemMaxUse=256M
      RuntimeMaxUse=64M
      MaxRetentionSec=14day
    '';
    systemd.coredump.extraConfig = ''
      Storage=none
      ProcessSizeMax=0
    '';
  };
}
