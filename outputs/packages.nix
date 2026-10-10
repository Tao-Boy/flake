{ pkgs }:
{
  # 直接导出锁定的上游包；不再维护仅用于 exec 的外部 shell 脚本。
  install = pkgs.nixos-anywhere;
  inherit (pkgs) nixos-anywhere;
  default = pkgs.nixos-anywhere;
}
