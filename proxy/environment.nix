{ lib }:
let
  # 与加密 JSON 中的本地监听端口保持一致。
  httpPort = 1081;
  socksPort = 1080;
  environment = {
    http_proxy = "http://127.0.0.1:${toString httpPort}";
    https_proxy = "http://127.0.0.1:${toString httpPort}";
    all_proxy = "socks5h://127.0.0.1:${toString socksPort}";
    no_proxy = "localhost,127.0.0.1,::1";
  };
in
environment // lib.mapAttrs' (name: value: lib.nameValuePair (lib.toUpper name) value) environment
