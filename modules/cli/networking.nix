{ pkgs, host, ... }: {
  networking = {
    hostName = "${host}";
    networkmanager.enable = true;
    timeServers = [ "ntp.aliyun.com" "ntp.tencent.com" ];
  };
}
