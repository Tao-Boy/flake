{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];

  # 根目录在内存中，每次重启清空；50% 是上限，不会提前占用内存。
  disko.devices.nodev."/" = {
    fsType = "tmpfs";
    mountOptions = [
      "size=50%"
      "mode=755"
    ];
  };

  # GPT 同时支持 BIOS / UEFI；/boot、/nix 和 /home 保存在磁盘上。
  disko.devices.disk.system = {
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        bios = {
          size = "1M";
          type = "EF02";
        };
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        # /home 的大小在机器的 storage.nix 中设置。
        home = {
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/home";
            mountOptions = [ "noatime" ];
          };
        };
        nix = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/nix";
            mountOptions = [ "noatime" ];
          };
        };
      };
    };
  };

  # /nix 已由 NixOS 纳入启动挂载；这里只补充 /home。
  fileSystems."/home".neededForBoot = true;

  # 根目录会清空，因此日志只保存在内存中，SSH 主机密钥放在持久的 /nix 分区。
  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=64M
    MaxRetentionSec=14day
  '';
  services.openssh.hostKeys = [
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
  # 同时输出到显示器和串口控制台，便于在服务商的网页控制台中查看。
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];

  # GRUB 同时支持 BIOS 与 UEFI 启动，保留最近 10 个系统版本。
  boot.loader = {
    efi.canTouchEfiVariables = false;
    grub = {
      enable = true;
      # BIOS boot 分区使 disko 自动生成同一整盘的 GRUB devices。
      efiSupport = true;
      efiInstallAsRemovable = true;
      configurationLimit = 10;
    };
  };
}
