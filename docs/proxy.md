# Xray 与加密 JSON

Xray 直接读取原生 JSON 配置，包含日志、入站、出站、路由、DNS 等全部选项。配置由用户维护，通过 SOPS + age 加密为 `secrets/xray.json`。仓库不提供自写脚本，全部由原生工具和 NixOS 选项完成：

| 环节 | 实现 |
| --- | --- |
| 加密、编辑、检查 | `sops` 命令与仓库根目录的 `.sops.yaml` |
| 部署时解密 | sops-nix：`format = "json"`、`key = ""`，整份解密到 `/run/secrets/xray.json` |
| 运行 Xray | nixpkgs 的 `services.xray`：动态用户，通过 `LoadCredential` 读取配置 |
| 终端与 Nix 守护进程的代理变量 | nixpkgs 的 `networking.proxy` |
| 开关 | NixOS 特化 `specialisation.proxy-off` 与 `switch-to-configuration` |

以上都在 `modules/nixos/services/proxy.nix`，机器只需导入它并设置 `local.proxy.configFile`。加密文件可以进入 Git 与 Nix store，明文配置和 age 私钥保存在仓库外。

## 首次准备

在仓库根目录进入开发环境（包含 `sops`、`age`、`xray`）：

```bash
nix develop
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt   # 已有私钥时跳过
age-keygen -y ~/.config/sops/age/keys.txt   # 输出 age1... 公钥
```

将输出的公钥替换 `.sops.yaml` 中的占位值。之后用示例创建密文、编辑并检查：

```bash
cp secrets/xray.example.json secrets/xray.json
sops encrypt --in-place secrets/xray.json
sops edit secrets/xray.json
sops exec-file --no-fifo --filename config.json secrets/xray.json 'xray run -test -config {}'
git add .sops.yaml secrets/xray.json
```

`sops edit` 打开完整的原生 Xray JSON，保存后自动写回密文；编辑器由 `EDITOR` 决定。最后一条命令把明文放进临时文件并执行 Xray 语法检查，输出 `Configuration OK.` 即通过。`--filename config.json` 让 Xray 根据扩展名识别 JSON，不能省略。私钥不在默认位置时，为上述命令设置 `SOPS_AGE_KEY_FILE=/安全路径/keys.txt`。

示例是 VLESS + Reality 客户端，使用 TCP、`xtls-rprx-vision`、Chrome 指纹和节点端口 443。示例节点没有访问权限，必须替换以下位置：

| JSON 位置 | 填写内容 |
| --- | --- |
| `outbounds[0].settings.vnext[0].address` | 节点地址 |
| `outbounds[0].settings.vnext[0].users[0].id` | 用户 UUID |
| `outbounds[0].streamSettings.realitySettings.serverName` | 节点要求的 SNI |
| `outbounds[0].streamSettings.realitySettings.password` | 服务商提供的 Reality 公钥，旧称 `publicKey` |
| `outbounds[0].streamSettings.realitySettings.shortId` | 十六进制 short ID；节点允许时可为空字符串 |

其他协议或路由规则直接在 JSON 中修改。示例 HTTP 代理监听 `127.0.0.1:1081`，SOCKS5 监听 `127.0.0.1:1080`；修改端口时，在机器入口同步设置 `local.proxy.httpPort` / `local.proxy.socksPort`。加密要求标准 JSON，不加入注释或尾随逗号。

已有完整明文配置时，直接加密到仓库，明文源文件放在仓库外：

```bash
sops encrypt --filename-override secrets/xray.json /安全路径/config.json > secrets/xray.json
```

提交密文并重建后，sops-nix 会在内容变化时重启 Xray；语法通过后仍需验证实际节点连通性。age 私钥应备份并保持受限权限。更换或增加公钥时修改 `.sops.yaml`，再执行 `sops updatekeys secrets/xray.json`。

## 机器配置

```nix
# machines/vps/default.nix
imports = [ ../../modules/nixos/services/proxy.nix ];
local.proxy.configFile = ../../secrets/xray.json;
```

| 选项 | 默认值 | 含义 |
| --- | --- | --- |
| `local.proxy.configFile` | 无 | SOPS 加密的完整 Xray JSON |
| `local.proxy.httpPort` | `1081` | 与 JSON 中 HTTP 入站一致 |
| `local.proxy.socksPort` | `1080` | 与 JSON 中 SOCKS5 入站一致 |
| `local.proxy.enable` | `true` | 由 `proxy-off` 特化设为 `false`，机器通常不需要修改 |

密文不存在或未 `git add` 时，求值会给出断言提示。不需要代理的机器不导入该模块，也不设置 `local.proxy.*`。

## 已安装系统的开关

age 私钥在目标机器的 `/nix/var/lib/sops-nix/key.txt` 中，由 root 持有，权限为 `0600`；父目录权限为 `0700`。该路径位于持久 ext4 分区，不受 tmpfs 根重启影响。已有机器先通过安全通道复制私钥到该路径，再重建；sops-nix 不自动生成或替换部署密钥。

```bash
proxy-off
proxy-on
systemctl is-active xray
```

系统构建时同时生成两套配置：默认配置运行 Xray 并设置代理变量；`proxy-off` 特化是去掉代理的同一份配置。`proxy-on` / `proxy-off` 是模块定义的 Bash 别名，实际执行：

```bash
# proxy-off
sudo /nix/var/nix/profiles/system/specialisation/proxy-off/bin/switch-to-configuration test
# proxy-on
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration test
```

切换由 NixOS 完成：启停 `xray.service`，更新登录环境，并按新环境重启 Nix 守护进程；请在正在运行的 Nix 构建或下载结束后切换。别名随后为当前 shell 执行 `export` / `unset`。新登录的会话自动使用新环境；其他已打开的会话和已经运行的程序需自行刷新。其他 shell 或脚本直接运行上面的命令。

`test` 不改变启动项，重启后回到默认开启。GRUB 菜单也会列出 `proxy-off` 配置，可以直接以无代理状态启动。开关以系统 profile（最近一次 `switch` 的配置）为准：用 `nixos-rebuild test` 临时激活的配置，在 `proxy-on` 后会回到 profile 中的版本。

需要长期取消代理时，从机器 imports 中移除该模块和 `local.proxy.configFile`。终端 HTTP/SOCKS 变量适用于支持代理变量的工具；SSH 等程序需按自身接口配置，系统未使用透明代理。

## NixOS LiveCD 中临时启用

先准备完整的加密 JSON 和对应 age 私钥，将私钥以 `0600` 权限放在仓库外。标准 NixOS LiveCD 不需要先安装系统或执行 `nixos-rebuild`，直接用 systemd 启动临时服务。在仓库根目录运行：

```bash
nix --extra-experimental-features 'nix-command flakes' shell .#sops .#xray
umask 077
SOPS_AGE_KEY_FILE=/安全路径/keys.txt sops decrypt secrets/xray.json \
  | sudo install -m 600 /dev/stdin /run/xray.json
sudo systemd-run --unit=xray --property=Restart=on-failure \
  "$(command -v xray)" run -config /run/xray.json

export http_proxy=http://127.0.0.1:1081 https_proxy=http://127.0.0.1:1081 \
  all_proxy=socks5h://127.0.0.1:1080 no_proxy=localhost,127.0.0.1,::1
sudo systemctl set-environment http_proxy="$http_proxy" https_proxy="$https_proxy" \
  all_proxy="$all_proxy" no_proxy="$no_proxy"
sudo systemctl restart nix-daemon.service
curl -I https://cache.nixos.org
```

`systemd-run` 创建位于 `/run` 的临时 `xray.service`；`systemctl set-environment` 让之后启动的服务（包括重启后的 Nix 守护进程）继承代理变量，`export` 作用于当前终端。明文配置在内存中的 `/run`，LiveCD 重启后与服务一同消失；临时服务不修改机器的硬件、磁盘或网络路由。关闭：

```bash
sudo systemctl stop xray.service
sudo systemctl unset-environment http_proxy https_proxy all_proxy no_proxy
sudo systemctl restart nix-daemon.service
unset http_proxy https_proxy all_proxy no_proxy
```

若首次下载 flake 输入或工具本身就被阻断，需要先从可联网环境带入工具；代理不能解决安装自身时的网络依赖。可在另一台 x86_64 Linux 机器复制锁定版本的工具闭包：

```bash
nix copy --to ssh://root@LIVECD .#sops .#xray
nix build --no-link --print-out-paths .#sops .#xray
```

最后一条输出两个 `/nix/store/...` 路径。经安全通道另行复制密文和 age 私钥后，在 LiveCD 用 `export PATH=/nix/store/实际路径-sops/bin:/nix/store/实际路径-xray/bin:$PATH` 代替上面的 `nix shell`，启动前不再需要解析 flake 或联网下载。

LiveCD 的 SSH 登录应由用户预先配置；上述复制命令不会设置登录凭据。也可在联网机器用 `nix copy --to file:///绝对路径/缓存 .#sops .#xray` 准备本地二进制缓存，经移动介质带入 LiveCD，使用 `sudo nix copy --from file:///介质/缓存 --no-check-sigs /nix/store/实际路径-sops /nix/store/实际路径-xray` 导入自己制作且确认来源的工具闭包。密钥单独保管，不放入工具闭包或二进制缓存。

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

代理仅作用于运行它的机器与其 Nix 守护进程。nixos-anywhere 切换到 kexec 环境或在另一台机器上构建时，不会自动把 LiveCD 的临时服务或环境变量传入新环境。远程安装在可联网或已启用代理的独立 Linux 构建机运行，使用 `--build-on local`；目标安装环境仍需联网的步骤应预先准备对应资源，不能假定重启后代理还存在。

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

## 从旧版本迁移

旧版的 `proxy` / `proxy-setup` 命令已移除，对应关系如下。已有的 `secrets/xray.json` 记录了加密所用的 age 公钥，无需重新加密，部署密钥也无需更换；只有新建文件或 `updatekeys` 时才读取 `.sops.yaml`。

| 旧命令 | 现在 |
| --- | --- |
| `proxy-setup init` | 上文“首次准备”中的 `age-keygen` 与 `sops encrypt` |
| `proxy-setup edit` | `sops edit secrets/xray.json` |
| `proxy-setup check` | `sops exec-file --no-fifo --filename config.json ... 'xray run -test -config {}'` |
| `proxy-setup live` 与 LiveCD 中的 `proxy on` / `off` | 上文 LiveCD 中的 `systemd-run` 与 `systemctl set-environment` |
| 已安装系统的 `sudo proxy on` / `off` | `proxy-on` / `proxy-off`，或直接运行 `switch-to-configuration test` |
| `proxy/environment.nix` 中的端口 | `local.proxy.httpPort` / `local.proxy.socksPort` |
| `sops.defaultSopsFile = ../../secrets/xray.json;` | `local.proxy.configFile = ../../secrets/xray.json;` |
| `home/programs/proxy.nix` | 不再需要；别名由系统模块提供 |

更早的 `secrets/xray.yaml` 只包含五个节点字段，不能直接改后缀使用：按“首次准备”从示例创建完整 JSON，填入原节点信息，Reality 公钥填入 `password`。

终端与 Nix 守护进程的代理变量现由 `networking.proxy` 提供，只设置小写的 `http_proxy`、`https_proxy`、`all_proxy`、`no_proxy`；只读取大写变量的工具需另行配置。

CI 在 NixOS 虚拟机中以明文示例运行该模块，验证 Xray 监听、Nix 守护进程与登录环境的代理变量，以及 `proxy-off` / `proxy-on` 对系统和当前 shell 的切换；不持有实际节点私钥，也不验证示例节点的外网连通性。
