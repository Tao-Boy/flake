report:
{
  config,
  lib,
  modulesPath,
  ...
}:
let
  hasReport = builtins.pathExists report;
  virtualisation = config.hardware.facter.report.virtualisation or null;
in
{
  # 没有报告时使用上游 QEMU profile；有报告时交给 NixOS facter 模块。
  imports = lib.optional (!hasReport) (modulesPath + "/profiles/qemu-guest.nix");
  hardware.facter.reportPath = if hasReport then report else null;
  services.qemuGuest.enable = lib.mkDefault (
    !hasReport
    || builtins.elem virtualisation [
      "qemu"
      "kvm"
      "bochs"
    ]
  );
}
