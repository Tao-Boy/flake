{ pkgs }:
let
  control = pkgs.callPackage ./default.nix { };
in
pkgs.writeShellApplication {
  name = "proxy-setup";
  runtimeInputs = [
    pkgs.age
    pkgs.coreutils
    pkgs.nano
    pkgs.sops
    pkgs.systemd
    pkgs.xray
  ];
  text = ''
    umask 077
    runtime=/run/xray-proxy
    decrypt() {
      SOPS_AGE_KEY_FILE="$key_file" sops --decrypt --input-type json --output-type json "$secret_file" > "$1"
      xray run -test -config "$1"
    }

    command=''${1:---help}
    secret_file=''${2:-secrets/xray.json}
    key_file=''${3:-''${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}}
    case "$command" in
      init|edit)
        if [ "$command" = init ]; then
          if [ -e "$secret_file" ]; then
            echo "密文已存在，请使用 proxy-setup edit 编辑。" >&2
            exit 1
          fi
          mkdir -p "$(dirname "$key_file")" "$(dirname "$secret_file")"
          if [ ! -e "$key_file" ]; then
            age-keygen -o "$key_file"
          fi
          sops --encrypt --age "$(age-keygen -y "$key_file")" --input-type json --output-type json \
            ${../secrets/xray.example.json} > "$secret_file"
        fi
        export SOPS_AGE_KEY_FILE="$key_file"
        export EDITOR="''${EDITOR:-nano}"
        sops "$secret_file"
        temporary=$(mktemp -d)
        trap 'rm -r "$temporary"' EXIT
        decrypt "$temporary/config.json"
        echo "配置语法检查通过；请确认已将示例值替换为真实节点，并提交加密 JSON。"
        ;;
      check)
        temporary=$(mktemp -d)
        trap 'rm -r "$temporary"' EXIT
        decrypt "$temporary/config.json"
        ;;
      live)
        if systemctl cat xray.service >/dev/null 2>&1; then
          echo "xray.service 已存在，请使用 proxy on 或 off。" >&2
          exit 1
        fi
        mkdir -p "$runtime"
        temporary=$(mktemp -d "$runtime/prepare.XXXXXX")
        trap 'rm -r "$temporary"' EXIT
        decrypt "$temporary/config.json"
        install -m 600 "$temporary/config.json" "$runtime/config.json"
        cat > /run/systemd/system/xray.service <<'UNIT'
    [Unit]
    Description=Xray proxy for NixOS LiveCD
    After=network-online.target
    [Service]
    DynamicUser=true
    LoadCredential=config.json:/run/xray-proxy/config.json
    ExecStart=${pkgs.xray}/bin/xray run -config %d/config.json
    Restart=on-failure
    RestartSec=5s
    NoNewPrivileges=true
    UNIT
        systemctl daemon-reload
        ${control}/bin/proxy on >/dev/null
        ;;
      --help|-h)
        echo 'proxy-setup init|edit|check [密文路径] [age 私钥路径]'
        echo 'sudo proxy-setup live [密文路径] [age 私钥路径]  # LiveCD 临时启动'
        ;;
      *)
        echo '未知操作；请运行 proxy-setup --help。' >&2
        exit 2
        ;;
    esac
  '';
}
