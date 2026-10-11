{ inputs, lib, ... }:
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
        home = {
          size = lib.mkDefault "4G";
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

  # 易失根的状态策略跟随存储布局，避免影响普通持久根的机器。
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
  boot.kernelParams = lib.mkAfter [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];

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
