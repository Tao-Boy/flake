# 可选服务

服务模块随 VPS baseline 导入，但 Nginx 和 Podman 默认关闭。具体域名、端口和应用属于 host 配置。

## Nginx 与 ACME

在 `hosts/vps/default.nix` 添加：

```nix
services.nginx = {
  enable = true;
  virtualHosts."app.example.com" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:3000";
      proxyWebsockets = true;
    };
  };
};
security.acme = {
  acceptTerms = true;
  defaults.email = "you@example.com";
};
```

替换域名和邮箱；确保域名的 A/AAAA 记录指向 VPS，服务商允许 80/443。模块会开启 NixOS 的 80/443 防火墙端口，并设置 Nginx 的常用代理、TLS、压缩和性能配置。后端绑定 localhost，避免额外暴露应用端口。

ACME 接受条款只在你明确启用并配置时设置，模板不会申请证书。

## Podman

```nix
fleet.containers.enable = true;
```

这会启用 Podman、Docker 兼容 CLI 和容器网络 DNS，但不会运行任何容器或公开 engine API。

可在 host 中声明由 systemd 管理的容器：

```nix
virtualisation.oci-containers = {
  backend = "podman";
  containers.app = {
    image = "docker.io/library/nginx:<已核对的版本或digest>";
    ports = [ "127.0.0.1:8080:80" ];
  };
};
```

上面的 image 是需替换的占位值。应用配置推荐固定镜像 digest；OCI 镜像并不由 `flake.lock` 自动锁定。明确设置持久化卷、备份和资源限额，数据不能只保存在可替换的容器层。

## 密钥

公开仓库只能存放公开的配置及公钥。不要提交私钥、密码、API token 或 ACME DNS 凭据。

Nix 表达式中的字符串通常会进入全局可读的 Nix store，即使它们来自未提交的文件也不自动保密。生产密钥应通过运行时 root 专用文件、systemd credentials，或另外配置的 sops-nix/agenix 注入。本模板不生成密钥，也不内置示例 token。

例如应用可使用 `environmentFile = "/var/lib/secrets/app.env";`，在部署前由你独立创建该文件并设置严格权限；不要使用 `pkgs.writeText` 创建明文密钥。
