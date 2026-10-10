# 可选服务

默认只启用 VPS 所需服务。额外服务通过 `machines/vps/default.nix` 的 `imports` 显式启用，再直接填写原生选项。

## Nginx 与 HTTPS

在现有 imports 加入：

```nix
../../modules/nixos/services/nginx.nix
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

替换域名/邮箱/后端，确保 DNS 指向服务器且服务商防火墙开放 80/443。ACME 密钥由系统在运行时生成，不进入 Git。当前 `/var` 位于 tmpfs，默认 `/var/lib/acme` 中的证书与密钥会在重启后消失；正式启用 HTTPS 前必须单独安排这些状态的持久存储，避免每次启动重新申请证书。

## Podman

在 imports 加入：

```nix
../../modules/nixos/services/containers.nix
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

rootless Podman 默认数据位于持久 `/home`；rootful Podman 和上面的系统容器默认在 `/var/lib/containers` 保存镜像和卷，会随重启清空。数据库、上传文件等容器数据请显式绑定持久目录，例如 `/home/tau/app-data:/data`，并设置符合容器 UID/GID 的文件权限。需要保留 rootful 镜像或其他运行状态时，另行配置其持久路径。

## 凭据

不要把密码、API token、私钥或容器环境文件写成 Nix 字符串，也不要用 `builtins.readFile` 将秘密复制进 Nix store。运行时文件放在受控目录中，例如：

```nix
virtualisation.oci-containers.containers.app.environmentFiles = [
  "/home/tau/.config/app/runtime.env"
];
```

将 `tau` 替换为实际用户名，文件权限设为仅账号或服务可读（例如 `0600`）。`/home` 持久化，默认 `/var` 中的秘密会在重启后丢失。

运行时路径只是引用，不会自动创建文件。手工管理受限权限文件，或按需要接入 sops-nix/agenix；先准备凭据，再启动依赖它的服务。
