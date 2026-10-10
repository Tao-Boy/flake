{
  # 机器清单：系统入口与用户模块选择。
  vps = {
    system = "x86_64-linux";
    module = ./vps;
    home = ./vps/home.nix;
  };
}
