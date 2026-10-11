{ lib, pkgs }:
let
  proxy = import ./settings.nix { inherit lib; };
  template = pkgs.writeText "xray-template.json" (
    builtins.toJSON (proxy.settings (lib.genAttrs proxy.secretNames (name: "@xray/${name}@")))
  );
  environmentOn = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") proxy.environment
  );
  environmentOff = "unset ${lib.concatStringsSep " " (builtins.attrNames proxy.environment)}";
  daemonOn = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: ''Environment="${name}=${value}"'') proxy.environment
  );
  daemonOff = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: _: ''Environment="${name}="'') proxy.environment
  );
  liveRunner = pkgs.writeShellScript "xray-live" ''
    exec ${pkgs.xray}/bin/xray run -config "$CREDENTIALS_DIRECTORY/config.json"
  '';
in
pkgs.writeShellApplication {
  name = "proxy";
  runtimeInputs = [
    pkgs.age
    pkgs.coreutils
    pkgs.jq
    pkgs.nano
    pkgs.sops
    pkgs.systemd
    pkgs.xray
  ];
  text = ''
    umask 077
    runtime=/run/xray-proxy
    dropin=/run/systemd/system/nix-daemon.service.d/90-xray-proxy.conf

    require_root() {
      if [ "$EUID" -ne 0 ]; then
        echo "请使用 sudo 运行此操作。" >&2
        exit 1
      fi
    }

    service_unit() {
      if systemctl cat xray.service >/dev/null 2>&1; then
        echo xray.service
      elif [ -f /run/systemd/system/xray-live.service ]; then
        echo xray-live.service
      else
        echo "尚未配置代理；LiveCD 请先执行 proxy live。" >&2
        exit 1
      fi
    }

    active() {
      systemctl is-active --quiet xray.service || systemctl is-active --quiet xray-live.service
    }

    daemon_environment() {
      mkdir -p "$(dirname "$dropin")"
      {
        echo '[Service]'
        if [ "$1" = on ]; then
          cat <<'ENV'
    ${daemonOn}
    ENV
        else
          cat <<'ENV'
    ${daemonOff}
    ENV
        fi
      } > "$dropin"
      systemctl daemon-reload
      systemctl try-restart nix-daemon.service
    }

    render() {
      SOPS_AGE_KEY_FILE="$key_file" sops --decrypt --input-type yaml --output-type json "$secret_file" |
        jq --slurpfile template ${template} '
          .xray as $secrets | $template[0] |
          walk(if type == "string"
               then if startswith("@xray/") then $secrets[.[6:-1]] else . end
               else . end)
        ' > "$1"
      xray run -test -config "$1"
    }

    command=''${1:---help}
    secret_file=''${2:-secrets/xray.yaml}
    key_file=''${3:-''${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}}
    case "$command" in
      init|edit)
        if [ "$command" = init ]; then
          if [ -e "$secret_file" ]; then
            echo "密文已存在，请使用 proxy edit 编辑。" >&2
            exit 1
          fi
          mkdir -p "$(dirname "$key_file")" "$(dirname "$secret_file")"
          if [ ! -e "$key_file" ]; then
            age-keygen -o "$key_file"
          fi
          sops --encrypt --age "$(age-keygen -y "$key_file")" --input-type yaml --output-type yaml \
            ${../secrets/xray.example.yaml} > "$secret_file"
        fi
        export SOPS_AGE_KEY_FILE="$key_file"
        export EDITOR="''${EDITOR:-nano}"
        sops "$secret_file"
        temporary=$(mktemp -d)
        trap 'rm -r "$temporary"' EXIT
        render "$temporary/config.json"
        echo "配置语法检查通过；请确认已将示例值替换为真实节点，并提交加密 YAML。"
        ;;
      check)
        temporary=$(mktemp -d)
        trap 'rm -r "$temporary"' EXIT
        render "$temporary/config.json"
        ;;
      live)
        require_root
        if systemctl cat xray.service >/dev/null 2>&1; then
          echo "已安装系统请使用 proxy on。" >&2
          exit 1
        fi
        mkdir -p "$runtime"
        temporary=$(mktemp -d "$runtime/prepare.XXXXXX")
        trap 'rm -r "$temporary"' EXIT
        render "$temporary/config.json"
        install -m 600 "$temporary/config.json" "$runtime/config.json"
        cat > /run/systemd/system/xray-live.service <<'UNIT'
    [Unit]
    Description=Xray proxy for NixOS LiveCD
    After=network-online.target
    [Service]
    DynamicUser=true
    LoadCredential=config.json:/run/xray-proxy/config.json
    ExecStart=${liveRunner}
    Restart=on-failure
    RestartSec=5s
    NoNewPrivileges=true
    UNIT
        systemctl daemon-reload
        systemctl restart xray-live.service
        daemon_environment on
        ;;
      on)
        require_root
        systemctl start "$(service_unit)"
        daemon_environment on
        ;;
      off)
        require_root
        daemon_environment off
        systemctl stop "$(service_unit)"
        ;;
      env)
        if active; then
          cat <<'ENV'
    ${environmentOn}
    ENV
        else
          echo ${lib.escapeShellArg environmentOff}
        fi
        ;;
      status)
        systemctl is-active "$(service_unit)"
        systemctl show nix-daemon.service --property=Environment --value
        ;;
      --help|-h)
        echo 'proxy init|edit|check [密文路径] [age 私钥路径]'
        echo 'sudo proxy live [密文路径] [age 私钥路径]  # LiveCD 临时启动'
        echo 'sudo proxy on|off; proxy status; eval "$(proxy env)"'
        ;;
      *)
        echo '未知操作；请运行 proxy --help。' >&2
        exit 2
        ;;
    esac
  '';
}
