{
  imports = [
    ../../modules/nixos
    ../../modules/home.nix
    ./hardware-configuration.nix
    ./storage.nix
  ];

  time.timeZone = "UTC";
  # 保留首次安装时的兼容版本，不随输入更新改变。
  system.stateVersion = "26.05";
}
