{ ... }: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../../modules/cli/i18n.nix
    ../../modules/cli/networking.nix
    ../../modules/cli/nix.nix
    ../../modules/cli/packages.nix
    ../../modules/cli/user.nix
    ../../modules/cli/zram.nix
    ../../home/gui/zathura.nix
    ../../home
  ];
  services.openssh = {
    enable = true;
    ports = [ 2333 ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
