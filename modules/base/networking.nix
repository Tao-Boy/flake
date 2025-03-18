{
  pkgs,
  hostName,
  ...
}: {
  networking = {
    hostName = "${hostName}";
    networkmanager.enable = true;
    timeServers = [
      "ntp.aliyun.com"
      "ntp.tencent.com"
    ];
  };
  environment.systemPackages = with pkgs; [networkmanagerapplet];
}
