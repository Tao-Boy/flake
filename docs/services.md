# 可选服务

默认只启用 VPS 所需服务。额外服务通过 `machines/vps/default.nix` 的 `imports` 显式启用，再直接填写原生选项。

## Nginx 与 HTTPS

在现有 imports 加入：

```nix
../../modules/nginx.nix
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

## 凭据

不要把密码、API token、私钥或环境文件写成 Nix 字符串，也不要用 `builtins.readFile` 将秘密复制进 Nix store。运行时文件放在受控目录中，例如：

```nix
systemd.services.app.serviceConfig.EnvironmentFile = "/home/tau/.config/app/runtime.env";
```

文件权限设为仅用户或服务可读（例如 `0600`）。`/home` 持久化，默认 `/var` 中的秘密会在重启后丢失。

运行时路径只是引用，不会自动创建文件。手工管理受限权限文件，或按需要接入 sops-nix/agenix；先准备凭据，再启动依赖它的服务。
