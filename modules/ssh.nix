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
