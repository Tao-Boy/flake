{
  # 机器清单；启用 Home Manager 的机器指定 home 入口。
  vps = {
    system = "x86_64-linux";
    module = ./vps;
    home = ./vps/home.nix;
  };
}
