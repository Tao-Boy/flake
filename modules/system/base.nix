{ config, lib, ... }:
{
  config = lib.mkIf config.fleet.enable {
    i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
    console.keyMap = lib.mkDefault "us";

    documentation.nixos.enable = lib.mkDefault false;
    environment.defaultPackages = lib.mkDefault [ ];

    services.qemuGuest.enable = lib.mkDefault true;
    services.chrony.enable = lib.mkDefault true;
    services.timesyncd.enable = lib.mkDefault false;

    # Keep the guest console available through the provider's VNC/serial console.
    boot.kernelParams = lib.mkAfter [ "console=tty0" "console=ttyS0,115200n8" ];
    boot.loader.timeout = lib.mkDefault 3;
  };
}
