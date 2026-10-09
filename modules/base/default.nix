{ lib, ... }:
{
  imports = [
    ./nix.nix
    ./users.nix
    ./packages.nix
  ];

  # mkDefault 表示共用默认值；hosts/ 中的普通赋值可以覆盖它。
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";
  documentation.nixos.enable = lib.mkDefault false;
  environment.defaultPackages = lib.mkDefault [ ];
}
