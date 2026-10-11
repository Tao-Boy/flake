{ config, lib, ... }:
let
  cfg = config.local.proxy;

  # 终端与 Nix 守护进程使用的本地代理地址，端口与加密 JSON 的 inbounds 一致。
  http = "http://127.0.0.1:${toString cfg.httpPort}";
  socks = "socks5h://127.0.0.1:${toString cfg.socksPort}";
  noProxy = "localhost,127.0.0.1,::1";
  variables = {
    http_proxy = http;
    https_proxy = http;
    all_proxy = socks;
    no_proxy = noProxy;
  };
  exports = lib.concatStringsSep " " (lib.mapAttrsToList (name: value: "${name}=${value}") variables);
  names = lib.concatStringsSep " " (builtins.attrNames variables);

  # 开关在系统 profile（启动默认配置）与其 proxy-off 特化之间切换。
  system = "/nix/var/nix/profiles/system";
in
{
  imports = [ ../sops.nix ];

  options.local.proxy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "运行 Xray 并为终端与 Nix 守护进程设置代理变量；proxy-off 特化中为 false。";
    };
    configFile = lib.mkOption {
      type = lib.types.path;
      description = "SOPS 加密的完整原生 Xray JSON。";
    };
    httpPort = lib.mkOption {
      type = lib.types.port;
      default = 1081;
      description = "Xray HTTP 入站端口。";
    };
    socksPort = lib.mkOption {
      type = lib.types.port;
      default = 1080;
      description = "Xray SOCKS5 入站端口。";
    };
  };

  config = lib.mkMerge [
    {
      # 两套配置中的命令保持一致，切换后仍可反向切换；之后同步当前 shell 的变量。
      environment.shellAliases = {
        proxy-on = "sudo ${system}/bin/switch-to-configuration test && export ${exports}";
        proxy-off = "sudo ${system}/specialisation/proxy-off/bin/switch-to-configuration test && unset ${names}";
      };
    }

    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = builtins.pathExists cfg.configFile;
          message = "local.proxy.configFile 不存在：请按 docs/proxy.md 创建加密的 Xray JSON，并执行 git add。";
        }
      ];

      # 解密整份原生 Xray JSON（key = ""），不提取字段或生成模板。
      sops.secrets."xray.json" = {
        sopsFile = cfg.configFile;
        format = "json";
        key = "";
        restartUnits = [ "xray.service" ];
      };

      # nixpkgs 原生模块：动态用户运行，通过 LoadCredential 读取解密后的配置。
      # mkDefault 便于测试改用明文示例。
      services.xray = {
        enable = true;
        settingsFile = lib.mkDefault config.sops.secrets."xray.json".path;
      };
      systemd.services.xray.serviceConfig = {
        Restart = "on-failure";
        RestartSec = "5s";
      };

      # 原生代理选项同时写入登录环境和 Nix 守护进程环境。
      networking.proxy = {
        httpProxy = http;
        httpsProxy = http;
        allProxy = socks;
        inherit noProxy;
      };
      systemd.services.nix-daemon.after = [ "xray.service" ];

      # 同一份配置去掉代理后的变体；也会出现在 GRUB 菜单中。
      specialisation.proxy-off.configuration.local.proxy.enable = false;
    })
  ];
}
