{ lib, ... }:
{
  imports = [
    ./shell.nix
    ./tools.nix
  ];

  # mkDefault 允许主机覆盖此值；首次使用后保留原值，不随软件升级修改。
  home.stateVersion = lib.mkDefault "26.05";
}
