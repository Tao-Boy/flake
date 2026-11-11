# Xray 客户端与服务端

Xray 由 NixOS 的 `services.xray` 模块声明。VPS 使用客户端模块，Oracle Cloud ARM 使用服务端模块：

| 主机 | 角色 | NixOS 模块 | 配置密文 |
| --- | --- | --- | --- |
| `vps` | VLESS Reality 客户端 | `modules/nixos/server/xray-client.nix` | `secrets/client.json` |
| `oracle-arm` | VLESS Reality 服务端 | `modules/nixos/server/xray-server.nix` | `secrets/server.json` |

两个 JSON 文件都由 sops 加密保存。sops-nix 在激活时将它们放到 `/run/secrets/`，然后通过 `services.xray.settingsFile` 交给 NixOS 的 Xray 模块。私钥不会写入 Nix store。

## 客户端

客户端在 VPS 上监听本机：

- SOCKS5：`127.0.0.1:10808`
- HTTP：`127.0.0.1:10809`

Xray 客户端默认不随系统启动。需要使用时在 VPS 上运行：

```bash
proxy-on      # 启动客户端并为当前终端设置代理变量
proxy-off     # 清除当前终端代理变量并停止客户端
proxy-status  # 查看客户端状态
```

代理变量只作用于执行别名的终端，其他已经打开的终端和 Nix 守护进程不受影响。

编辑客户端配置：

```bash
sops edit secrets/client.json
sops exec-file --no-fifo --filename client.json secrets/client.json \
  'xray run -test -config {}'
```

修改连接到服务端的地址、UUID、Reality 公钥、短 ID 或服务名时，必须同时检查 `server.json` 中对应的服务端配置。更换 `.sops.yaml` 中的公钥后执行：

```bash
sops updatekeys secrets/client.json
```

## 服务端

Oracle ARM 服务端使用 VLESS Reality，监听 TCP 2333，并由 `xray-server.nix` 启用系统服务。服务端配置包含 Reality 私钥，保存在：

```text
secrets/server.json
```

服务端会随系统启动，不使用 `proxy-on` / `proxy-off`。修改服务端配置前检查：

```bash
sops exec-file --no-fifo --filename server.json secrets/server.json \
  'xray run -test -config {}'
```

服务端密钥轮换时，需要同时更新：

1. `server.json` 中的 Reality 私钥和短 ID；
2. `client.json` 中对应的 Reality 公钥和短 ID；
3. 客户端连接的 Oracle 公网地址；
4. Oracle Cloud 安全列表和网络安全组中的 TCP 2333 入站规则。

Oracle 配置默认把启动卷写为 `/dev/sda`，安装前先用 `lsblk` 核对设备。Xray 监听 TCP 2333，Ignis 通过共用 Nginx 模块监听 TCP 80/443；两者使用不同端口，可以同时运行。

## 配置变更后的验证

```bash
nix develop
sops exec-file --no-fifo --filename client.json secrets/client.json \
  'xray run -test -config {}'
sops exec-file --no-fifo --filename server.json secrets/server.json \
  'xray run -test -config {}'
nix fmt
nix flake check --no-write-lock-file
```

## LiveCD 临时使用

LiveCD 中不需要加载 NixOS 模块，可以临时解密并启动其中一个配置：

```bash
nix --extra-experimental-features 'nix-command flakes' shell .#sops .#xray
SOPS_AGE_KEY_FILE=/安全路径/keys.txt \
  sops decrypt secrets/server.json | sudo install -m 600 /dev/stdin /run/xray-server.json
sudo systemd-run --unit=xray "$(command -v xray)" run -config /run/xray-server.json
```

明文配置只位于 LiveCD 的 `/run`，重启后消失。客户端配置也可以把 `server.json` 替换为 `client.json`。
