{ inputs }:
{
  name = "proxy-switch";

  node.specialArgs = { inherit inputs; };
  nodes.machine =
    { lib, ... }:
    {
      imports = [ ../modules/nixos/services/proxy.nix ];
      local.proxy.configFile = ../secrets/xray.example.json;
      # 测试不持有 age 私钥：跳过解密，直接把明文示例交给 Xray。
      sops.secrets = lib.mkForce { };
      services.xray.settingsFile = ../secrets/xray.example.json;
    };

  testScript = ''
    def proxy_is_on():
        machine.wait_for_unit("xray.service")
        machine.wait_for_open_port(1080)
        machine.wait_for_open_port(1081)
        machine.succeed("systemctl show nix-daemon --property=Environment | grep -F https_proxy=http://127.0.0.1:1081")
        machine.succeed("grep -F https_proxy /etc/set-environment")

    def proxy_is_off():
        machine.fail("systemctl is-active xray.service")
        machine.fail("systemctl show nix-daemon --property=Environment | grep -F https_proxy")
        machine.fail("grep -F https_proxy /etc/set-environment")

    machine.wait_for_unit("multi-user.target")
    # 测试虚拟机直接从系统闭包启动，补上开关使用的系统 profile。
    machine.succeed("ln -s $(readlink -f /run/current-system) /nix/var/nix/profiles/system")

    with subtest("默认启用代理"):
        proxy_is_on()

    with subtest("proxy-off 切换系统并清除当前 shell 的变量"):
        machine.succeed("bash -lic 'proxy-off && test -z \"''${https_proxy+x}\"'")
        proxy_is_off()

    with subtest("proxy-on 恢复代理并设置当前 shell 的变量"):
        machine.succeed("bash -lic 'proxy-on && test \"$https_proxy\" = http://127.0.0.1:1081'")
        proxy_is_on()
  '';
}
