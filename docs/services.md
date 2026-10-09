# 可选服务

默认只启用 VPS 所需服务。额外服务通过 `hosts/vps/default.nix` 的 `imports` 显式启用，再直接填写原生选项。

## Nginx 与 HTTPS

在现有 imports 加入：

```nix
../../modules/nixos/nginx.nix
```

该模块启用 Nginx 推荐参数并开放 TCP 80/443。HTTPS 还需要在主机中配置：

```nix
security.acme = {
  acceptTerms = true;
  defaults.email = "you@example.com";
};
services.nginx.virtualHosts."example.com" = {
  enableACME = true;
  forceSSL = true;
  locations."/" = {
    proxyPass = "http://127.0.0.1:3000";
    proxyWebsockets = true;
  };
};
```

替换域名/邮箱/后端，确保 DNS 指向服务器且服务商防火墙开放 80/443。ACME 密钥由系统在运行时生成，不进入 Git。

## Podman

在 imports 加入：

```nix
../../modules/nixos/containers.nix
```

该模块启用 Podman、Docker 命令兼容和容器 DNS。系统容器可声明在主机配置：

```nix
virtualisation.oci-containers = {
  backend = "podman";
  containers.web = {
    image = "docker.io/library/nginx:stable"; # 生产环境优先固定 digest
    ports = [ "127.0.0.1:8080:80" ];
  };
};
```

示例仅绑定本机，可由 Nginx 反代；公网服务需要明确配置监听地址、防火墙和认证。rootless Podman 使用账号的 subordinate UID/GID 范围，按 `podman info` 与实际应用检查。

## 凭据

不要把密码、API token、私钥或容器环境文件写成 Nix 字符串，也不要用 `builtins.readFile` 将秘密复制进 Nix store。运行时文件放在受控目录中，例如：

```nix
virtualisation.oci-containers.containers.app.environmentFiles = [
  "/var/lib/app/runtime.env"
];
```

运行时路径只是引用，不会自动创建文件。手工管理受限权限文件，或按需要接入 sops-nix/agenix；先准备凭据，再启动依赖它的服务。
