{ lib, pkgs }:
let
  proxy = import ./settings.nix { inherit lib; };
  daemonOn = pkgs.writeText "proxy-on.conf" (
    "[Service]\n"
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: ''Environment="${name}=${value}"'') proxy.environment
    )
  );
  daemonOff = pkgs.writeText "proxy-off.conf" (
    "[Service]\n"
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: _: ''Environment="${name}="'') proxy.environment
    )
  );
  environmentOn = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") proxy.environment
  );
  environmentOff = "unset ${lib.concatStringsSep " " (builtins.attrNames proxy.environment)}";
in
pkgs.writeShellApplication {
  name = "proxy";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.systemd
  ];
  text = ''
    case "''${1:-}" in
      on)
        action=start
        daemon=${daemonOn}
        environment=${lib.escapeShellArg environmentOn}
        ;;
      off)
        action=stop
        daemon=${daemonOff}
        environment=${lib.escapeShellArg environmentOff}
        ;;
      *)
        echo '用法：sudo proxy on|off' >&2
        exit 2
        ;;
    esac

    install -D -m 644 "$daemon" /run/systemd/system/nix-daemon.service.d/90-xray-proxy.conf
    systemctl daemon-reload
    systemctl "$action" xray.service
    systemctl try-restart nix-daemon.service
    # 子进程不能修改调用者环境，由 Bash 快捷命令执行这些 export / unset。
    printf '%s\n' "$environment"
  '';
}
