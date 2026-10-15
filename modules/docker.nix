{ config, ... }:
let
  userHome = config.users.users.tau.home;
  dataDir = "${userHome}/.openai4s-data";
in
{
  # Docker 引擎
  virtualisation.docker.enable = true;

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0700 tau users - -"
  ];

  # 声明式 OCI 容器
  virtualisation.oci-containers = {
    backend = "docker";

    containers.openai4s = {
      image = "ghcr.io/tao-boy/openai4s:0.3.0";

      autoStart = true;

      ports = [
        "127.0.0.1:8760:8760"
      ];

      # 数据持久化
      volumes = [
        "${dataDir}:/data"
      ];

      # 普通环境变量
      environment = {
        OPENAI4S_SECRET_STORE = "plaintext";
        OPENAI4S_KERNEL_SANDBOX = "auto";
      };

      # API Key 不写入 Nix Store
      environmentFiles = [
      ];

      # 最多等待 120 秒正常停止
      extraOptions = [
        "--stop-timeout=120"
      ];
    };
  };
}
