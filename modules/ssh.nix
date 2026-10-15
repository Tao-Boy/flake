{ config, ... }:
{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      MaxAuthTries = 3;
      LoginGraceTime = 30;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
    };
    hostKeys = [
      {
        type = "ed25519";
        path = "/etc/ssh/ssh_host_ed25519_key";
      }
    ];
  };

  sops.secrets."id_ed25519" = {
    sopsFile = ../secrets/id_ed25519;
    format = "binary";
    owner = "tau";
    mode = "0600";
  };

  programs.ssh.extraConfig = ''
    Match localuser tau
      IdentityFile ${config.sops.secrets."id_ed25519".path}
      IdentitiesOnly yes
    Match all
  '';

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "24h";
    };
  };
}
