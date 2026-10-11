{ lib }:
let
  httpPort = 1081;
  socksPort = 1080;
  environment = {
    http_proxy = "http://127.0.0.1:${toString httpPort}";
    https_proxy = "http://127.0.0.1:${toString httpPort}";
    all_proxy = "socks5h://127.0.0.1:${toString socksPort}";
    no_proxy = "localhost,127.0.0.1,::1";
  };
in
{
  environment =
    environment // lib.mapAttrs' (name: value: lib.nameValuePair (lib.toUpper name) value) environment;
  secretNames = [
    "address"
    "id"
    "serverName"
    "publicKey"
    "shortId"
  ];

  settings = secrets: {
    log.loglevel = "warning";
    inbounds = [
      {
        listen = "127.0.0.1";
        port = socksPort;
        protocol = "socks";
        settings.auth = "noauth";
      }
      {
        listen = "127.0.0.1";
        port = httpPort;
        protocol = "http";
      }
    ];
    outbounds = [
      {
        protocol = "vless";
        settings.vnext = [
          {
            inherit (secrets) address;
            port = 443;
            users = [
              {
                inherit (secrets) id;
                encryption = "none";
                flow = "xtls-rprx-vision";
              }
            ];
          }
        ];
        streamSettings = {
          network = "tcp";
          security = "reality";
          realitySettings = {
            fingerprint = "chrome";
            inherit (secrets) serverName shortId;
            password = secrets.publicKey;
          };
        };
      }
    ];
  };
}
