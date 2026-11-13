# 可选服务

`vps-pi` 启用 Xray 客户端、pi-web、Fast Note Sync、Podman 和 Nginx/ACME；`vps-dev` 启用开发环境和 Xray 客户端；Oracle ARM 启用 Xray Reality 与 Ignis。额外服务通过对应主机的 `imports` 显式启用，再直接填写原生选项。

## pi-web 容器

`vps-pi` 使用上游发布的 `ghcr.io/agegr/pi-web:latest`，通过 NixOS 的 OCI containers 模块交给 Podman 管理。所有容器服务都复用 `modules/nixos/server/podman.nix`，镜像与容器可写层统一存储在 `/var/lib/containers/storage`。镜像不锁定 digest，每次服务启动都会拉取最新标签。容器内监听 `0.0.0.0:30141`，宿主只发布 `127.0.0.1:30141`，由 Nginx 在 `pi.nullcode.cc` 提供 HTTPS 和 WebSocket。

容器只将 `/home/tau/pi-workspace` 按同一路径读写挂载，工作目录与容器的 `HOME` 均设为该目录；不挂载 `/nix` 或整个宿主家目录。目录由系统以 `0700 tau users` 自动创建，容器按 `tau` 的 UID 和 `users` 的 GID 运行。agent 数据位于 `pi-workspace/.pi/agent`，全局 skills 可放在 `pi-workspace/.agents/skills`，项目也放在工作区内。Pi Web 的“使用默认目录”会在工作区下创建 `pi-cwd/YYYYMMDD`。这些数据随工作区持久保存；宿主原有的 `.pi` 配置、会话和项目不会自动导入。

环境变量保存在 SOPS 加密的 `secrets/server.env` 中。系统将整份 dotenv 文件解密到 `/run/secrets/pi-web.env`，权限为 root 的 `0400`，Podman 在启动时读取该文件，凭据更新会重启 `podman-pi-web.service`。当前密文由原有 `/home/tau/.config/pi-web/server.env` 导入，保留其中的配置；后续修改使用：

```bash
sops edit secrets/server.env
```

解密内容采用 Podman 的 `KEY=value` 格式，例如 `PI_WEB_PASSWORD=...`，不添加 `export`、值两侧的引号或 shell 变量展开。明文只在运行时提供，不写入仓库或 Nix store；部署时无需在用户家目录另行准备 `server.env`。域名白名单由模块设置，启动参数固定内部监听地址和端口。容器使用镜像内的工具，有独立网络；如配置代理，地址须能从容器内访问。

更新镜像和查看日志：

```bash
sudo systemctl restart podman-pi-web.service
sudo systemctl status podman-pi-web.service
sudo journalctl -u podman-pi-web.service -f
```

从旧版 npm 用户服务切换的步骤见[部署说明](deployment.md#pi-web-切换到-podman)。

## Fast Note Sync 笔记同步

`vps-pi` 在 `https://sync.nullcode.cc` 提供 [Fast Note Sync Service](https://github.com/haierkeys/fast-note-sync-service/blob/master/docs/README.zh-CN.md)，供 Obsidian Fast Note Sync 插件使用。配置位于 `modules/nixos/server/fast-note-sync.nix`，使用官方 Docker 镜像 `docker.io/haierkeys/fast-note-sync-service:latest`，由已有的 Podman 后端管理，启动时拉取最新镜像。

容器以 `tau` 的 UID/GID 运行，仅将 `9000` 发布到宿主 `127.0.0.1:9000`。Nginx 负责 ACME 证书、HTTP 跳转 HTTPS、WebSocket 升级和长连接转发；请求体上限为 128 MiB，并关闭代理缓冲以支持同步和流式接口。仅需对外开放已有的 TCP 80/443，无需开放 9000。

持久目录由系统以 `0700 tau users` 创建：

| 宿主路径 | 容器路径 | 内容 |
| --- | --- | --- |
| `/home/tau/fast-note-sync/config` | `/fast-note-sync/config` | `config.yaml`、认证密钥等服务配置 |
| `/home/tau/fast-note-sync/storage` | `/fast-note-sync/storage` | SQLite 数据库、笔记/附件、日志及其他服务数据 |

部署前，将 `sync.nullcode.cc` 的 DNS A 记录指向 `vps-pi`；如添加 AAAA 记录，也应指向该服务器可用的 IPv6 地址。按[部署说明](deployment.md#日常更新)重建已采用仓库 ext4 根布局的 `vps-pi` 后，容器会自动启动。当前仍用根 tmpfs 的旧机器须先完成该文档中的布局迁移。

首次启动时，上游会在空的 `config` 目录中生成 `config.yaml`，并生成随机的认证令牌密钥。随后：

1. 打开 `https://sync.nullcode.cc`，注册并登录自己的账号。
2. 编辑 `/home/tau/fast-note-sync/config/config.yaml`，在现有 `server` 配置中设置 `ext-api-url: "https://sync.nullcode.cc"`。个人使用时，在现有 `user` 配置中把 `register-is-enable` 改为 `false`，并将 `admin-uid` 设为自己账号的实际数字 ID，限制管理员身份；保留已有其他设置及认证密钥。
3. 执行下面的重启命令，重新登录 Web 管理界面，点击“复制 API 配置”，粘贴到 Obsidian Fast Note Sync 插件中。确认地址使用 `https://sync.nullcode.cc`；WebSocket 同步入口为 `wss://sync.nullcode.cc/api/user/sync`。

```bash
sudo systemctl restart podman-fast-note-sync.service
sudo systemctl status podman-fast-note-sync.service
sudo journalctl -u podman-fast-note-sync.service -n 100 --no-pager
curl -I https://sync.nullcode.cc
```

没有默认账号密码，账号由应用注册流程创建。配置与认证密钥在运行时生成并留在私有持久目录中，不写入 Nix store 或 Git。使用上面的重启命令拉取新镜像并更新容器，不使用 Web 管理界面的二进制自更新；容器内的非 root 用户无权替换镜像中的程序。备份或升级前，停止 `podman-fast-note-sync.service` 并同时备份整个 `/home/tau/fast-note-sync`（包括隐藏文件），以保持 SQLite、附件和配置一致，然后重新启动服务。

## Nginx 与 HTTPS

`hosts/vps-pi/default.nix` 已在 imports 中加入：

```nix
../../modules/nixos/server/pi-web.nix
```

该模块把 `pi.nullcode.cc` 反向代理到本机的 pi-web（`127.0.0.1:30141`）。Fast Note Sync 模块将 `sync.nullcode.cc` 转发到 `127.0.0.1:9000`。这些服务与 Ignis 模块都导入 `modules/nixos/server/nginx.nix`，统一设置 Nginx 推荐参数、TCP 80/443 和 ACME 邮箱；域名、后端、认证与日志策略分别保留在站点模块中。新增站点先导入共用 Nginx 模块，再声明虚拟主机：

```nix
services.nginx.virtualHosts."example.com" = {
  enableACME = true;
  forceSSL = true;
  locations."/" = {
    proxyPass = "http://127.0.0.1:3000";
    proxyWebsockets = true;
  };
};
```

替换域名和后端；需要更换 ACME 邮箱时修改共用 Nginx 模块。确保 DNS 指向服务器且服务商防火墙开放 80/443。ACME 密钥由系统在运行时生成，不进入 Git。按仓库 ext4 根布局安装后，`/var/lib/acme` 重启后仍然存在；当前本机旧 tmpfs 布局的迁移见[部署说明](deployment.md#旧布局迁移到-ext4-根分区)。

Oracle ARM 的 Ignis 使用独立模块 `modules/nixos/server/ignis.nix`：Podman 容器只绑定 localhost，Nginx 在 `ob.nullcode.cc` 提供 HTTPS、Basic Auth 和 WebSocket 代理；Basic Auth 的 htpasswd 文件由 SOPS 在运行时解密。OCI 网络层仍需开放 TCP 80/443 才能签发和续期 ACME 证书。

Ignis 的持久数据统一放在用户家目录的 `ignis/` 下，由系统以 `0750 tau users` 创建。容器通过 `PUID` / `PGID` 使用该用户身份访问数据：

| 宿主路径 | 容器路径 | 内容 |
| --- | --- | --- |
| `/home/tau/ignis/vaults` | `/vaults` | 笔记库及各库的 `.obsidian` 配置与插件文件 |
| `/home/tau/ignis/data` | `/app/data` | Ignis 插件管理、同步等应用状态 |
| `/home/tau/ignis/obsidian-app` | `/app/obsidian-app` | Obsidian 应用资源缓存 |

镜像与容器可写层仍由 Podman 存在 `/var/lib/containers/storage`。原先使用 `/var/lib/ignis` 的部署需先按[部署说明](deployment.md#oracle-cloud-ampere-arm)复制数据，再切换配置。

## 凭据

Ignis 的 Basic Auth 哈希位于 SOPS 加密的 `secrets/ignis.htpasswd`，不能把密码或哈希直接写进 Nix 字符串或 Nix store。变更方式见[部署说明](deployment.md#oracle-cloud-ampere-arm)。


不要把密码、API token、私钥或环境文件写成 Nix 字符串，也不要用 `builtins.readFile` 将秘密复制进 Nix store。运行时文件放在受控目录中，例如：

```nix
systemd.services.app.serviceConfig.EnvironmentFile = "/home/tau/.config/app/runtime.env";
```

文件权限设为仅用户或服务可读（例如 `0600`）。按仓库布局安装后，家目录和 `/var` 都在持久化的 ext4 根文件系统中；运行时路径仍需由管理员或相应服务创建。
