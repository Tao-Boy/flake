# 接收一个参数集：软件源、共用值和具体主机的配置入口。
{ inputs, myvars, name, nixosModule, homeModule }:
inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";

  # specialArgs 让 NixOS 模块可以接收 myvars 参数。
  specialArgs = {
    myvars = myvars;
  };

  modules = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    nixosModule
    {
      # mkDefault 设置默认值，主机文件仍可直接覆盖它。
      networking.hostName = inputs.nixpkgs.lib.mkDefault name;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";

        # pkgs 使用系统稳定源；新版本工具显式选择 pkgsUnstable。
        extraSpecialArgs = {
          myvars = myvars;
          pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages."x86_64-linux";
        };

        # ${myvars.username} 将用户名作为属性名，例如 users.tau。
        users.${myvars.username} = import homeModule;
      };
    }
  ];
}
