{
  # 不安装 NixOS 手册和默认附带的软件，保持系统精简。
  documentation.nixos.enable = false;
  environment.defaultPackages = [ ];

  nix.settings = {
    # 启用 nix 命令和 flakes。
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true; # 相同文件在 /nix/store 中只存一份
    max-jobs = 1; # 同时构建的任务数，小内存 VPS 保持为 1
  };

  # 每周删除 14 天前的旧系统版本，释放磁盘空间。
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
