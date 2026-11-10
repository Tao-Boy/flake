# 可选服务

默认只启用 VPS 所需服务。额外服务通过 `hosts/vps/default.nix` 的 `imports` 显式启用，再直接填写原生选项。

## Nginx 与 HTTPS

vps 已在 imports 中加入：

```nix
../../modules/nixos/server/nginx.nix
```

该模块启用 Nginx 推荐参数、开放 TCP 80/443，并把 `pi.nullcode.cc` 反向代理到本机的 pi-web（`127.0.0.1:30141`）。ACME 设置直接写在模块中，新增站点可仿照：

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

替换域名、邮箱和后端，确保 DNS 指向服务器且服务商防火墙开放 80/443。ACME 密钥由系统在运行时生成，不进入 Git。根文件系统是持久 ext4，因此 `/var/lib/acme` 重启后仍然存在。

## 凭据

不要把密码、API token、私钥或环境文件写成 Nix 字符串，也不要用 `builtins.readFile` 将秘密复制进 Nix store。运行时文件放在受控目录中，例如：

```nix
systemd.services.app.serviceConfig.EnvironmentFile = "/home/tau/.config/app/runtime.env";
```

文件权限设为仅用户或服务可读（例如 `0600`）。家目录和 `/var` 都在持久化的 ext4 根文件系统中；运行时路径仍需由管理员或相应服务创建。
