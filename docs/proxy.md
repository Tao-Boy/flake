# Xray 与加密 JSON

Xray 读取原生 JSON 配置。配置加密保存为 `secrets/xray.json`，开机时由 sops-nix 用服务器的 SSH 主机密钥解密到 `/run/secrets/xray.json`。相关设置都在 `modules/proxy.nix`。

## 创建与编辑配置

密钥的准备见[安装说明](deployment.md#准备)。本机的 `sops` 使用 `~/.config/sops/age/keys.txt` 中的管理密钥。

```bash
nix develop
# 已有明文配置时加密进仓库，明文放在仓库外
sops encrypt --filename-override secrets/xray.json /安全路径/config.json > secrets/xray.json
# 之后直接编辑密文，保存后自动重新加密
sops edit secrets/xray.json
# 检查语法，输出 Configuration OK. 即通过
sops exec-file --no-fifo --filename config.json secrets/xray.json 'xray run -test -config {}'
git add secrets/xray.json
```

加密要求标准 JSON，不能有注释或尾随逗号。配置中 HTTP 入站监听 `127.0.0.1:10809`，SOCKS5 入站监听 `127.0.0.1:10808`；修改端口时同步修改 `modules/proxy.nix` 开头的 `http` / `socks`。

更换 `.sops.yaml` 中的公钥后执行 `sops updatekeys secrets/xray.json`。重建后，sops-nix 会在密文变化时重启 Xray。

## 已安装系统的开关

Xray 开机不自动启动，需要时在服务器上手动开启：

```bash
proxy-on      # 启动 Xray，并为当前终端设置代理变量
proxy-off     # 清除当前终端的代理变量，停止 Xray
proxy-status  # 查看 Xray 是否运行
```

这些是 `modules/proxy.nix` 定义的 Bash 别名。代理变量只作用于执行别名的终端，其他已打开的终端和 Nix 守护进程不受影响。不需要代理的机器从 imports 中删掉 `../../modules/proxy.nix`。

## NixOS LiveCD 中临时启用

把密文仓库和管理密钥复制到 LiveCD，管理密钥放在仓库外、权限 `0600`。在仓库根目录运行：

```bash
nix --extra-experimental-features 'nix-command flakes' shell .#sops .#xray
SOPS_AGE_KEY_FILE=/安全路径/keys.txt sops decrypt secrets/xray.json \
  | sudo install -m 600 /dev/stdin /run/xray.json
sudo systemd-run --unit=xray "$(command -v xray)" run -config /run/xray.json

export http_proxy=http://127.0.0.1:10809 https_proxy=http://127.0.0.1:10809 \
  all_proxy=socks5h://127.0.0.1:10808
sudo systemctl set-environment http_proxy="$http_proxy" https_proxy="$https_proxy" all_proxy="$all_proxy"
sudo systemctl restart nix-daemon.service
```

`systemctl set-environment` 让重启后的 Nix 守护进程也使用代理。明文配置在内存中的 `/run`，LiveCD 重启后消失。关闭：

```bash
sudo systemctl stop xray.service
sudo systemctl unset-environment http_proxy https_proxy all_proxy
sudo systemctl restart nix-daemon.service
unset http_proxy https_proxy all_proxy
```

LiveCD 无法下载 `sops`、`xray` 时，在可联网的 x86_64 Linux 机器上运行 `nix copy --to ssh://root@LIVECD .#sops .#xray` 复制过去，再用 `nix build --no-link --print-out-paths .#sops .#xray` 输出的路径设置 `PATH`。

## LiveCD 本机安装

LiveCD 已启用代理后，按[安装说明](deployment.md#准备)准备好主机密钥，然后：

```bash
nix build .#nixosConfigurations.vps.config.system.build.toplevel --out-link work/system
nix build .#nixosConfigurations.vps.config.system.build.diskoScript --out-link work/disko
# 下条命令会清空 storage.nix 指定的整盘，并挂载到 /mnt。
sudo "$(readlink -f work/disko)"
sudo cp -r work/extra-files/nix/persist /mnt/nix/
sudo nixos-install --system "$(readlink -f work/system)" --no-root-passwd
```

`cp -r` 由 root 执行，复制出的文件归 root 所有，私钥保持 `600`。完成后由你重启进入已安装系统。
