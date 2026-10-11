# Xray 与加密 JSON

Xray 直接读取原生 JSON 配置，包含日志、入站、出站、路由、DNS 等全部选项。配置由用户维护，通过 SOPS + age 加密为 `secrets/xray.json`；Nix 只接入密钥、声明 systemd 服务和提供开关工具。

已安装系统由 sops-nix 以 `format = "json"`、`key = ""` 解密整份文件到 `/run/secrets/xray.json`。systemd 用 `LoadCredential` 将该文件交给动态用户运行的 Xray，直接执行 `xray run -config`。加密文件可以进入 Git 与 Nix store，真实明文配置和 age 私钥保存在仓库外。

## 首次准备

在仓库根目录运行：

```bash
nix run .#proxy-setup -- init
git add secrets/xray.json
```

工具创建 `~/.config/sops/age/keys.txt`（已有私钥则复用），加密 `secrets/xray.example.json` 并打开编辑器。编辑器中看到的是完整的原生 Xray JSON；保存后写回密文，并执行 Xray 语法检查。

示例是 VLESS + Reality 客户端，使用 TCP、`xtls-rprx-vision`、Chrome 指纹和节点端口 443。示例节点没有访问权限，必须替换以下位置：

| JSON 位置 | 填写内容 |
| --- | --- |
| `outbounds[0].settings.vnext[0].address` | 节点地址 |
| `outbounds[0].settings.vnext[0].users[0].id` | 用户 UUID |
| `outbounds[0].streamSettings.realitySettings.serverName` | 节点要求的 SNI |
| `outbounds[0].streamSettings.realitySettings.password` | 服务商提供的 Reality 公钥，旧称 `publicKey` |
| `outbounds[0].streamSettings.realitySettings.shortId` | 十六进制 short ID；节点允许时可为空字符串 |

其他协议或路由规则直接在 JSON 中修改。示例 HTTP 代理监听 `127.0.0.1:1081`，SOCKS5 监听 `127.0.0.1:1080`；若修改端口，同步修改 `proxy/environment.nix`，保证终端与 Nix 守护进程使用正确地址。配置使用 Xray 所支持的 JSON 格式；加密工具要求标准 JSON，不加入注释或尾随逗号。

已有 age 私钥时显式指定路径：

```bash
nix run .#proxy-setup -- init secrets/xray.json /安全路径/keys.txt
nix run .#proxy-setup -- edit secrets/xray.json /安全路径/keys.txt
nix run .#proxy-setup -- check secrets/xray.json /安全路径/keys.txt
```

也可设置 `SOPS_AGE_KEY_FILE` 与 `EDITOR`。编辑后的密文提交并重建，sops-nix 会在内容变化时重启 Xray；语法通过后仍需验证实际节点连通性。age 私钥应备份并保持受限权限。

已有完整明文配置时，也可直接加密。明文源文件放在仓库外：

```bash
nix develop
sops --encrypt --age "$(age-keygen -y /安全路径/keys.txt)" \
  --input-type json --output-type json /安全路径/config.json > secrets/xray.json
nix run .#proxy-setup -- check secrets/xray.json /安全路径/keys.txt
git add secrets/xray.json
```

机器通过导入 `modules/nixos/services/xray.nix` 选择代理，在自己的入口指定 `sops.defaultSopsFile`。Home Manager 快捷函数由该机器的 `home.nix` 选择 `home/programs/proxy.nix`。

## 从旧配置迁移

旧版 `secrets/xray.yaml` 只包含五个节点字段，不能直接改后缀使用。运行新工具的 `init`，在完整 JSON 中填写原节点信息，或按上述命令加密已有的原生 JSON。Reality 公钥填入 `password`；保留原 age 私钥时，目标系统的部署密钥无需更换。

提交新的 `secrets/xray.json` 后重建并验证代理，再移除不再使用的旧 YAML。旧 `proxy/settings.nix` 中的协议、路由等定制也应移入 JSON；公开的本地代理地址保留在 `proxy/environment.nix`。

## 已安装系统的开关

age 私钥在目标机器的 `/nix/var/lib/sops-nix/key.txt` 中，由 root 持有，权限为 `0600`；父目录权限为 `0700`。该路径位于持久 ext4 分区，不受 tmpfs 根重启影响。已有机器先通过安全通道复制私钥到该路径，再重建；sops-nix 不自动生成或替换部署密钥。

```bash
proxy-on
proxy-off
systemctl is-active xray
```

`proxy` 只接受 `on` 和 `off`，直接控制 `xray.service` 和 Nix 守护进程环境；状态用原生 `systemctl` 查看。凭据与 LiveCD 初始化统一使用 `proxy-setup`。

`proxy-on` / `proxy-off` 是 Bash 函数：调用系统命令切换服务，随后更新当前 shell 的代理变量。新 Bash 会话按服务当前状态设置变量。其他 shell 或脚本使用：

```bash
environment=$(sudo proxy on) && eval "$environment"
environment=$(sudo proxy off) && eval "$environment"
```

开关通过 `/run/systemd/system/` 中的临时覆盖设置 Nix 守护进程的代理环境，并重启该守护进程；请在正在运行的 Nix 构建或下载结束后切换。变化影响 Nix 守护进程、新启动的命令及执行了 `eval` 的当前 shell，其他已打开的会话和已经运行的程序需自行刷新。

默认每次启动系统都启用代理。`off` 的运行时状态在重启后清除；需要长期取消时，从机器 imports 中移除 Xray 模块、相关 `sops.defaultSopsFile` 设置和用户快捷函数导入。终端 HTTP/SOCKS 变量适用于支持代理变量的工具；SSH 等程序需按自身接口配置，系统未使用透明代理。

## NixOS LiveCD 中临时启用

先准备完整的加密 JSON 和对应 age 私钥，将私钥以 `0600` 权限放在仓库外。标准 NixOS LiveCD 不需要先安装系统或执行 `nixos-rebuild`。在仓库根目录运行：

```bash
sudo nix --extra-experimental-features 'nix-command flakes' run .#proxy-setup -- \
  live "$PWD/secrets/xray.json" /安全路径/keys.txt
environment=$(sudo nix --extra-experimental-features 'nix-command flakes' run .#proxy -- on)
eval "$environment"
curl -I https://cache.nixos.org
```

初始化工具解密并检查配置，创建位于 `/run` 的临时 `xray.service`，同时为 LiveCD 的 Nix 守护进程启用代理。工具和原生 JSON 与已安装系统共用，临时服务不修改机器的硬件、磁盘或网络路由。LiveCD 重启后服务和解密配置消失。开关仍使用 `nix run .#proxy -- on` 或 `off`，通过上述 `environment=$(sudo ...)` 与 `eval` 同步当前终端。已安装系统和 LiveCD 共用同一个服务名，开关直接执行 systemd 启停命令。

若首次下载 flake 输入或工具本身就被阻断，需要先从可联网环境带入工具；代理不能解决安装自身时的网络依赖。可在另一台 x86_64 Linux 机器构建并复制完整工具闭包：

```bash
nix build .#proxy --out-link work/proxy
nix build .#proxy-setup --out-link work/proxy-setup
nix copy --to ssh://root@LIVECD .#proxy .#proxy-setup
readlink -f work/proxy work/proxy-setup
```

最后一条输出开关工具和初始化工具的两个 `/nix/store/...` 路径。经安全通道另行复制密文和 age 私钥后，在 LiveCD 直接使用该工具路径，启动前不再需要解析 flake 或联网下载：

```bash
sudo /nix/store/实际路径-proxy-setup/bin/proxy-setup live /路径/xray.json /安全路径/keys.txt
environment=$(sudo /nix/store/实际路径-proxy/bin/proxy on)
eval "$environment"
```

LiveCD 的 SSH 登录应由用户预先配置；上述复制命令不会设置登录凭据。也可在联网机器用 `nix copy --to file:///绝对路径/缓存 .#proxy .#proxy-setup` 准备本地二进制缓存，经移动介质带入 LiveCD，使用 `sudo nix copy --from file:///介质/缓存 --no-check-sigs /nix/store/实际路径-proxy /nix/store/实际路径-proxy-setup` 导入自己制作且确认来源的工具闭包。密钥单独保管，不放入工具闭包或二进制缓存。

## 安装时保留部署密钥

LiveCD 临时代理解密使用的私钥，还需提供给安装后的系统。准备 nixos-anywhere 的额外文件目录：

```bash
umask 077
mkdir -p work/extra-files/nix/var/lib/sops-nix
install -m 600 /安全路径/keys.txt work/extra-files/nix/var/lib/sops-nix/key.txt
nix run .#install -- --flake .#vps --target-host root@YOUR_SERVER \
  --extra-files "$PWD/work/extra-files" --build-on local \
  --generate-hardware-config nixos-generate-config ./machines/vps/hardware-configuration.nix
```

`work/` 已被 Git 忽略。安装完成后清理临时副本并保管原密钥。安装仍会按 disko 布局擦除指定磁盘，公钥、磁盘和硬件生成流程见[安装说明](deployment.md)。

代理仅作用于运行开关的机器与其 Nix 守护进程。nixos-anywhere 切换到 kexec 环境或在另一台机器上构建时，不会自动把 LiveCD 的临时服务、环境变量或运行时覆盖传入新环境。远程安装在可联网或已启用代理的独立 Linux 构建机运行，使用 `--build-on local`；目标安装环境仍需联网的步骤应预先准备对应资源，不能假定重启后代理还存在。

## LiveCD 本机安装

在待安装机器的 LiveCD 已启用代理后，可以沿用适用的硬件模板，或由用户显式生成硬件配置：

```bash
sudo nixos-generate-config --show-hardware-config --no-filesystems \
  > machines/vps/hardware-configuration.nix
git add machines/vps/hardware-configuration.nix secrets/xray.json
```

核对公钥和整盘路径后，先在 LiveCD 构建完整系统及分区脚本，再执行会擦盘的安装步骤：

```bash
nix build .#nixosConfigurations.vps.config.system.build.toplevel --out-link work/system
nix build .#nixosConfigurations.vps.config.system.build.diskoScript --out-link work/disko
# 下条命令会清空 storage.nix 指定的整盘，并挂载到 /mnt。
sudo "$(readlink -f work/disko)"
sudo install -d -m 700 /mnt/nix/var/lib/sops-nix
sudo install -m 600 /安全路径/keys.txt /mnt/nix/var/lib/sops-nix/key.txt
sudo nixos-install --system "$(readlink -f work/system)" --no-root-passwd
```

完整系统已在 LiveCD 的 Nix store 中构建，`nixos-install` 复制已有闭包并安装启动项，代理一直留在当前 LiveCD 中运行。完成后核对 `/mnt/nix/var/lib/sops-nix/key.txt` 权限、保存硬件文件和密文、清理临时密钥副本，再由用户重启进入已安装系统。使用原生安装流程不会自动执行重启，也不会额外生成硬件或网络配置。

CI 使用临时 age 密钥加密完整 JSON 示例，验证整份配置的加密解密一致性、Xray 语法、NixOS 构建、LiveCD 服务监听以及开关对终端与 Nix 守护进程环境的影响，不持有实际节点私钥，也不验证示例节点的外网连通性。
