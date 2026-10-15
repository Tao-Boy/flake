{ inputs, ... }:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # 根目录 / 是 tmpfs，每次重启清空。下面列出的路径实际保存在磁盘上的 /nix/persist 中，
  # 开机时挂载回原位置；其余文件都由 NixOS 根据配置重新生成。
  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [
      # 用户 tau 的家目录；需写明所有者，否则会被创建为 root 所有
      {
        directory = "/home/tau";
        user = "tau";
        group = "users";
        mode = "0700";
      }
      "/var/log" # 系统日志
      "/var/lib/nixos" # 用户与组的 UID / GID 分配记录
      "/var/lib/acme" # Let's Encrypt 证书与账户，避免每次重启重新申请而触发频率限制
      "/var/lib/fail2ban" # 封禁记录，使 bantime-increment 跨重启生效
      # Docker 数据（启用 modules/docker.nix 时使用）
      "/var/lib/docker"
      "/var/lib/containerd"
      "/var/lib/systemd" # 定时任务记录、随机数种子、网络状态等
    ];
    files = [
      "/etc/machine-id" # 机器标识，DHCP 用它生成客户端标识，保持地址稳定
      "/etc/ssh/ssh_host_ed25519_key" # SSH 主机私钥，同时用于 sops 解密
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
}
