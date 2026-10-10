{
  imports = [
    ../../profiles/nixos/server.nix
    ./hardware.nix
    ./storage.nix
  ];

  time.timeZone = "UTC";
  # 保留首次安装时的兼容版本，不随输入更新改变。
  system.stateVersion = "26.05";
}
