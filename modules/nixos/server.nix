{ lib, myvars, ... }:
{
  # 这些默认设置可以在 hosts/vps/default.nix 中直接覆盖。
  services.qemuGuest.enable = lib.mkDefault true;
  services.chrony.enable = lib.mkDefault true;
  services.fstrim.enable = lib.mkDefault true;
  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = "zstd";
    memoryPercent = lib.mkDefault 50;
  };
  # 日志只保留本次启动，与临时根目录的行为一致。
  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=64M
    MaxRetentionSec=14day
  '';
  systemd.coredump.settings.Coredump = {
    Storage = "none";
    ProcessSizeMax = 0;
  };

  # 具体网卡和地址写在 hosts/ 中；这里启用 VPS 共用的网络服务。
  networking = {
    useDHCP = false;
    useNetworkd = true;
    nftables.enable = true;
    firewall.enable = true;
  };
  services.resolved.enable = true;

  # SSH 模块默认监听 22，并自动开放配置端口的防火墙规则。
  services.openssh = {
    enable = true;
    # 主机私钥由 sshd 自动生成并保留在 /nix，重启不会改变指纹。
    hostKeys = [
      {
        type = "ed25519";
        path = "/nix/var/lib/sshd/ssh_host_ed25519_key";
      }
      {
        type = "rsa";
        bits = 4096;
        path = "/nix/var/lib/sshd/ssh_host_rsa_key";
      }
    ];
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
    bantime-increment = {
      enable = true;
      maxtime = "24h";
    };
    jails.sshd.settings = {
      backend = "systemd";
      findtime = "10m";
    };
  };

  # mkAfter 将串口控制台参数追加到其他模块提供的参数之后。
  boot.kernelParams = lib.mkAfter [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];
  boot.loader.timeout = lib.mkDefault 3;
  boot.kernel.sysctl = {
    "net.ipv4.tcp_syncookies" = lib.mkDefault 1;
    "net.ipv4.conf.all.accept_redirects" = lib.mkDefault 0;
    "net.ipv4.conf.default.accept_redirects" = lib.mkDefault 0;
    "net.ipv4.conf.all.send_redirects" = lib.mkDefault 0;
    "net.ipv6.conf.all.accept_redirects" = lib.mkDefault 0;
  };
}
