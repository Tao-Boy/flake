{ lib, ... }:
let
  proxyEnvironment = import ../../proxy/environment.nix { inherit lib; };
  environmentOn = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") proxyEnvironment
  );
  environmentOff = "unset ${lib.concatStringsSep " " (builtins.attrNames proxyEnvironment)}";
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
