{ lib, myvars, ... }:
{
  services.qemuGuest.enable = lib.mkDefault true;
  services.chrony.enable = lib.mkDefault true;
  services.fstrim.enable = lib.mkDefault true;
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = "zstd";
    memoryPercent = lib.mkDefault 50;
  };
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=256M
    RuntimeMaxUse=64M
    MaxRetentionSec=14day
  '';
  systemd.coredump.settings.Coredump = {
    Storage = "none";
    ProcessSizeMax = 0;
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    nftables.enable = true;
    firewall.enable = true;
  };
  services.resolved.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ myvars.username ];
      X11Forwarding = false;
      MaxAuthTries = 3;
      LoginGraceTime = 30;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      LogLevel = "VERBOSE";
    };
  };
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = { enable = true; maxtime = "24h"; };
    jails.sshd.settings = { backend = "systemd"; findtime = "10m"; };
  };

  boot.kernelParams = lib.mkAfter [ "console=tty0" "console=ttyS0,115200n8" ];
  boot.loader.timeout = lib.mkDefault 3;
  boot.kernel.sysctl = {
    "net.ipv4.tcp_syncookies" = lib.mkDefault 1;
    "net.ipv4.conf.all.accept_redirects" = lib.mkDefault 0;
    "net.ipv4.conf.default.accept_redirects" = lib.mkDefault 0;
    "net.ipv4.conf.all.send_redirects" = lib.mkDefault 0;
    "net.ipv6.conf.all.accept_redirects" = lib.mkDefault 0;
  };
}
