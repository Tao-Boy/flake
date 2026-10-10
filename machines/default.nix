{
  # 新增机器只增加一项；系统、用户环境和检查由同一清单生成。
  vps = {
    system = "x86_64-linux";
    module = ./vps;
    home = ../home/machines/vps.nix;
  };
}
