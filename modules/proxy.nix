{
  config,
  inputs,
  lib,
  ...
}:
let
  # 本地代理地址，端口与 secrets/xray.json 中的 inbounds 一致。
  http = "http://127.0.0.1:1081";
  socks = "socks5h://127.0.0.1:1080";
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # 1. 解密：开机时用 ~/.ssh 中的 age 私钥把整份 Xray JSON 解密到 /run/secrets/xray.json。
  sops.age.keyFile = "/home/tau/.ssh/age.key";
  sops.age.sshKeyPaths = [ ]; # 只用上面的私钥，不从 SSH 主机密钥派生
  sops.gnupg.sshKeyPaths = [ ];
  sops.secrets."xray.json" = {
    sopsFile = ../secrets/xray.json;
    format = "json";
    key = ""; # 空字符串表示解密整份文件
    restartUnits = [ "xray.service" ]; # 密文变化时重启 Xray
  };

  # 2. 运行 Xray：使用 NixOS 自带的 services.xray 模块。
  services.xray = {
    enable = true;
    settingsFile = config.sops.secrets."xray.json".path;
  };

  # 3. 代理变量：登录终端和 Nix 守护进程都通过 Xray 联网。
  networking.proxy = {
    httpProxy = http;
    httpsProxy = http;
    allProxy = socks;
    noProxy = "localhost,127.0.0.1,::1";
  };

  # 4. 关闭代理的备用配置：在上面的基础上停用 Xray、清空代理变量。
  #    它会和默认配置一起构建，也会出现在开机菜单中。
  specialisation.proxy-off.configuration = {
    services.xray.enable = lib.mkForce false;
    networking.proxy = {
      httpProxy = lib.mkForce null;
      httpsProxy = lib.mkForce null;
      allProxy = lib.mkForce null;
      noProxy = lib.mkForce null;
    };
  };

  # 5. 开关命令：在默认配置和 proxy-off 之间切换，并更新当前终端的变量。
  #    test 只切换当前运行状态，重启后回到默认（开启代理）。
  environment.shellAliases = {
    proxy-on = "sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test && export http_proxy=${http} https_proxy=${http} all_proxy=${socks} no_proxy=localhost,127.0.0.1,::1";
    proxy-off = "sudo /nix/var/nix/profiles/system/specialisation/proxy-off/bin/switch-to-configuration test && unset http_proxy https_proxy all_proxy no_proxy";
  };
}
