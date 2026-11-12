{ pkgs, ... }:
{
  # GCC, Make, uv and Node.js are provided by the other selected user modules.
  home.packages = [
    pkgs.python3
    pkgs.pkg-config
    pkgs.gdb
  ];
}
