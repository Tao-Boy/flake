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
    # 主机密钥放在 ~/.ssh，根目录清空后仍保留，客户端不会提示指纹变化。
    hostKeys = [
      {
        type = "ed25519";
        path = "/home/tau/.ssh/ssh_host_ed25519_key";
      }
      {
        type = "rsa";
        bits = 4096;
        path = "/home/tau/.ssh/ssh_host_rsa_key";
      }
    ];
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
