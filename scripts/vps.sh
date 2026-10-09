#!/usr/bin/env bash
set -euo pipefail

die() { printf '错误：%s\n' "$*" >&2; exit 1; }
usage() {
  cat <<'USAGE'
在仓库根目录执行（本机需要启用 Nix flakes）：
  nix run .#preflight -- HOST
  nix run .#install -- HOST root@SERVER [--port 22] [--identity PATH]
                         [--build-on auto|local|remote] [--dry-run]
  nix run .#rebuild -- HOST ops@SERVER [--port PORT] [--identity PATH]
                         [--action test|switch|boot|dry-activate|build]
install 会清空目标磁盘，必须在终端中输入完整确认文字。
rebuild 默认执行 test；确认第二个 SSH 会话正常后再执行 switch。
--port 指当前远端 SSH 端口。安装器 kexec 阶段使用 22。
USAGE
}

[[ $# -gt 0 ]] || { usage; exit 0; }
command=$1
shift
case "$command" in
  help|--help|-h) usage; exit 0 ;;
  preflight|install|rebuild) ;;
  *) die "未知命令：$command" ;;
esac
[[ "${1:-}" != --help && "${1:-}" != -h ]] || { usage; exit 0; }
[[ $# -gt 0 ]] || die "缺少主机名"
host=$1
shift
[[ "$host" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]] || die "主机名格式错误"

target=""
if [[ "$command" != preflight ]]; then
  [[ $# -gt 0 ]] || die "缺少 SSH 目标"
  target=$1
  shift
  [[ "$target" != -* && "$target" != *[[:space:]]* && "$target" != */* ]] \
    || die "SSH 目标格式错误"
fi

port=""
identity=""
build_on=auto
action="test"
dry_run=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --port|--identity|--build-on|--action)
      [[ $# -ge 2 ]] || die "$1 缺少参数"
      case "$1" in
        --port) port=$2 ;;
        --identity) identity=$2 ;;
        --build-on)
          [[ "$command" == install ]] || die "--build-on 仅用于首次安装"
          build_on=$2 ;;
        --action)
          [[ "$command" == rebuild ]] || die "--action 仅用于日常更新"
          action=$2 ;;
      esac
      shift 2 ;;
    --dry-run)
      [[ "$command" == install ]] || die "--dry-run 仅用于首次安装"
      dry_run=true
      shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "未知参数：$1" ;;
  esac
done
case "$build_on" in auto|local|remote) ;; *) die "不支持的构建方式" ;; esac
case "$action" in test|switch|boot|dry-activate|build) ;; *) die "不支持的更新动作" ;; esac

[[ -f flake.nix && -f flake.lock ]] || die "请先 cd 到克隆后的 flake 仓库根目录"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "请在 Git 仓库中运行"
[[ "$(nix eval --raw --no-write-lock-file \
  ".#nixosConfigurations.${host}.config.nixpkgs.hostPlatform.system")" == x86_64-linux ]] \
  || die "仅支持 x86_64-linux"

metadata=$(nix eval --json --no-write-lock-file ".#nixosConfigurations.${host}.config.fleet")
admin=$(jq -r '.access.adminUser' <<<"$metadata")
disk=$(jq -r '.diskDevice' <<<"$metadata")
boot_mode=$(jq -r '.bootMode' <<<"$metadata")
final_port=$(jq -r '.access.sshPort' <<<"$metadata")
[[ "$disk" =~ ^/dev/[a-zA-Z0-9_./:-]+$ ]] || die "磁盘路径包含不支持的字符"

keys=$(nix eval --json --no-write-lock-file \
  ".#nixosConfigurations.${host}.config.users.users.${admin}.openssh.authorizedKeys.keys")
jq -e 'length > 0 and all(.[]; type == "string" and (contains("\n") | not))' \
  <<<"$keys" >/dev/null || die "必须配置至少一个完整的 SSH 公钥"

temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
while IFS= read -r key; do
  printf '%s\n' "$key" >"$temp_dir/key.pub"
  ssh-keygen -lf "$temp_dir/key.pub" >/dev/null 2>&1 || die "SSH 公钥无效，请填写完整 .pub 内容"
done < <(jq -r '.[]' <<<"$keys")

# Force NixOS assertions, package references and disko script evaluation.
nix eval --raw --no-write-lock-file \
  ".#nixosConfigurations.${host}.config.system.build.toplevel.drvPath" >/dev/null
nix eval --raw --no-write-lock-file \
  ".#nixosConfigurations.${host}.config.system.build.diskoScript.drvPath" >/dev/null

printf '主机=%s  管理员=%s  磁盘=%s  启动=%s  安装后SSH端口=%s\n' \
  "$host" "$admin" "$disk" "$boot_mode" "$final_port"
jq '.network' <<<"$metadata"
if [[ -n "$(git status --porcelain)" ]]; then
  printf '提示：工作区有改动；新建的 Nix 文件必须先 git add 才能被 flake 读取。\n' >&2
fi
[[ "$command" != preflight ]] || exit 0

if [[ -z "$port" ]]; then
  if [[ "$command" == install ]]; then port=22; else port=$final_port; fi
fi
[[ "$port" =~ ^[0-9]+$ && ${#port} -le 5 ]] || die "SSH 端口无效"
port=$((10#$port))
((port >= 1 && port <= 65535)) || die "SSH 端口无效"
ssh_options=(-o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=15 -p "$port")
if [[ -n "$identity" ]]; then
  [[ -f "$identity" ]] || die "私钥文件不存在"
  ssh_options+=(-o IdentitiesOnly=yes -i "$identity")
fi

if [[ "$command" == install ]]; then
  # All operations before confirmation are read-only.
  ssh "${ssh_options[@]}" "$target" \
    'test "$(uname -m)" = x86_64 && test "$(id -u)" = 0' \
    || die "首次安装需要 x86_64 目标上的 root SSH 权限"
  printf '%s\\n' "$disk" | ssh "${ssh_options[@]}" "$target" \
    'IFS= read -r disk; test -b "$disk"' \
    || die "目标磁盘不存在或不是块设备"
  firmware=$(ssh "${ssh_options[@]}" "$target" \
    'if test -d /sys/firmware/efi; then echo uefi; else echo bios; fi')
  [[ "$boot_mode" == hybrid || "$boot_mode" == "$firmware" ]] \
    || die "配置启动模式与目标当前固件模式不一致"
  ssh "${ssh_options[@]}" "$target" \
    'lsblk -dpno NAME,SIZE,TYPE,MODEL; ip -br address; ip route'
  printf '确认将清空 %s 上的 %s；当前固件=%s。\n' "$target" "$disk" "$firmware"
  if [[ "$dry_run" == true ]]; then
    printf '只读预检完成，未运行安装器。\n'
    exit 0
  fi
  [[ -t 0 ]] || die "磁盘擦除确认必须在交互终端执行"
  confirmation="ERASE $target $disk"
  read -r -p "请输入 $confirmation ：" reply
  [[ "$reply" == "$confirmation" ]] || die "未确认，停止安装"

  args=(--flake ".#$host" --target-host "$target" --ssh-port "$port"
        --post-kexec-ssh-port 22 --build-on "$build_on" --print-build-logs)
  [[ -z "$identity" ]] || args+=(-i "$identity")
  # nixos-anywhere manages temporary installer credentials across kexec itself.
  nixos-anywhere "${args[@]}"
  printf '安装完成后：ssh -p %s %s@<服务器地址>\n' "$final_port" "$admin"
else
  # Check the existing connection before requesting any activation.
  ssh "${ssh_options[@]}" "$target" 'sudo -n true' \
    || die "日常更新需要配置管理员的免密码 sudo 权限"
  # nixos-rebuild-ng uses shlex.split; jq @sh preserves each argument exactly.
  options_json=$(printf '%s\0' "${ssh_options[@]}" | jq -Rs 'split("\u0000")[:-1]')
  NIX_SSHOPTS=$(jq -nr --argjson opts "$options_json" '$opts | @sh')
  export NIX_SSHOPTS
  nixos-rebuild "$action" --flake ".#$host" --target-host "$target" --sudo \
    --no-write-lock-file --print-build-logs
  if [[ "$action" == test ]]; then
    printf 'test 已临时应用；请用第二个 SSH 会话验证，再执行 --action switch。\n'
    printf '若连接丢失，通过服务商控制台重启会回到上次持久化的配置。\n'
  fi
fi
