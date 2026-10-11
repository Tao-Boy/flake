{ config, ... }:
{
  # 只允许公钥登录，禁止 root 登录。
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
    # 主机密钥由下面的 sops 解密得到，重装或重启后指纹不变。
    hostKeys = [
      {
        type = "ed25519";
        path = config.sops.secrets.ssh_host_ed25519_key.path;
      }
    ];
  };

  # 主机私钥加密保存在 secrets/ssh_host_ed25519_key，开机时解密到 /run/secrets/。
  sops.secrets.ssh_host_ed25519_key = {
    sopsFile = ../secrets/ssh_host_ed25519_key;
    format = "binary"; # 整个文件就是私钥本身
    restartUnits = [ "sshd.service" ]; # 密钥变化时重启 SSH（已有会话不受影响）
  };

  # 多次登录失败的 IP 会被临时封禁，屡犯者封禁时间递增。
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
