{ config, lib, ... }:
let cfg = config.fleet;
in
{
  config = lib.mkIf cfg.enable {
    users.mutableUsers = false;
    users.users.root.hashedPassword = "!";
    users.users.${cfg.access.adminUser} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPassword = "!";
      openssh.authorizedKeys.keys = cfg.access.sshPublicKeys;
    };
    # Keys are the credential; this account intentionally has no usable password.
    security.sudo.wheelNeedsPassword = false;
    services.openssh = {
      enable = true;
      openFirewall = false;
      ports = [ cfg.access.sshPort ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = [ cfg.access.adminUser ];
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
      jails.sshd.settings = {
        backend = "systemd";
        findtime = "10m";
      };
    };
  };
}
