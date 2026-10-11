{ lib, ... }:
let
  proxy = import ../../proxy/settings.nix { inherit lib; };
  environmentOn = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") proxy.environment
  );
  environmentOff = "unset ${lib.concatStringsSep " " (builtins.attrNames proxy.environment)}";
in
{
  programs.bash.initExtra = ''
    # 新终端跟随服务状态，避免关闭后仍沿用父进程的代理变量。
    if systemctl is-active --quiet xray.service; then
      ${environmentOn}
    else
      ${environmentOff}
    fi

    proxy-on() { local environment; environment=$(sudo proxy on) && eval "$environment"; }
    proxy-off() { local environment; environment=$(sudo proxy off) && eval "$environment"; }
  '';
}
