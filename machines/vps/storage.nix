{
  imports = [ ../../modules/file-system.nix ];

  disko.devices.disk.system.device = "/dev/vda";
  disko.devices.disk.system.content.partitions.home.size = "8G";
}
