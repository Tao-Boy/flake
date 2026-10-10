{
  lib,
  pkgs,
  nixpkgs,
  users,
  nixosConfigurations,
  source,
}:
let
  systems = lib.filterAttrs (
    _: machine: machine.config.nixpkgs.hostPlatform.system == pkgs.stdenv.hostPlatform.system
  ) nixosConfigurations;
  machineChecks = lib.concatMapAttrs (name: machine: {
    "home-${name}" = machine.config.home-manager.users.${users.username}.home.activationPackage;
    "system-${name}" = machine.config.system.build.toplevel;
    "disk-${name}" = machine.config.system.build.diskoScript;
  }) systems;
in
machineChecks
// {
  install = pkgs.nixos-anywhere;
  evaluation = import ./evaluation.nix {
    inherit
      lib
      pkgs
      nixpkgs
      users
      nixosConfigurations
      ;
  };
  # 保留已有 home 检查名称，便于原有命令继续使用。
  home = nixosConfigurations.vps.config.home-manager.users.${users.username}.home.activationPackage;
  quality =
    pkgs.runCommand "nix-quality"
      {
        nativeBuildInputs = [
          pkgs.nixfmt
          pkgs.statix
          pkgs.deadnix
        ];
      }
      ''
        find ${source} -name '*.nix' -print0 | xargs -0 nixfmt --check
        statix check ${source}
        deadnix --fail ${source}
        touch "$out"
      '';
  persistence-vps =
    (nixosConfigurations.vps.extendModules {
      modules = [ ./persistence.nix ];
    }).config.system.build.installTest;
}
