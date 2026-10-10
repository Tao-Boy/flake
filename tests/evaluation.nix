{
  lib,
  pkgs,
  users,
  nixosConfigurations,
}:
let
  vps = nixosConfigurations.vps.config;
  static =
    (nixosConfigurations.vps.extendModules {
      modules = [
        {
          networking.useDHCP = false;
          systemd.network.networks."10-uplink" = {
            matchConfig.Name = "ens3";
            address = [ "203.0.113.10/24" ];
            routes = [ { Gateway = "203.0.113.1"; } ];
          };
        }
      ];
    }).config;
  tests = [
    {
      assertion = !(static.systemd.network.networks ? "99-ethernet-default-dhcp");
      message = "Static networks must not retain the generic DHCP rule.";
    }
    {
      assertion =
        vps.system.stateVersion == "26.05"
        && vps.home-manager.users.${users.username}.home.stateVersion == "26.05";
      message = "Restructuring must preserve system and home compatibility versions.";
    }
    {
      assertion =
        vps.users.users.${users.username}.uid == 1000
        && vps.services.openssh.settings.PermitRootLogin == "no";
      message = "Restructuring must preserve administrator identity and SSH policy.";
    }
    {
      assertion = vps.boot.loader.grub.devices == [ vps.disko.devices.disk.system.device ];
      message = "GRUB and disko must use the same explicit target disk.";
    }
  ];
in
assert lib.all (test: lib.assertMsg test.assertion test.message) tests;
pkgs.runCommand "configuration-evaluation" { } ''
  touch "$out"
''
