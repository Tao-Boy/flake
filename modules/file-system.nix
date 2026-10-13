{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices.nodev."/" = {
    fsType = "tmpfs";
    mountOptions = [
      "size=50%"
      "mode=755"
    ];
  };

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

  # 日志保存在持久化的 /var/log（见 modules/impermanence.nix），限制占用空间。
  services.journald.extraConfig = "SystemMaxUse=256M";

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
