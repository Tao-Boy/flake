{ self, nixpkgs, ... }@inputs:
let
  system = "x86_64-linux";
  lib = nixpkgs.lib;
  pkgs = nixpkgs.legacyPackages.${system};
  myvars = import ../vars;
  mkSystem = import ../lib/nixos-system.nix { inherit inputs myvars; };
  scriptTools = with pkgs; [
    bash coreutils git jq openssh nix nixos-anywhere nixos-rebuild
  ];
  vps = pkgs.writeShellApplication {
    name = "vps";
    runtimeInputs = scriptTools;
    text = builtins.readFile ../scripts/vps.sh;
  };
  commands = {
    install = "Install a VPS with preflight and disk confirmation";
    rebuild = "Update a VPS with nixos-rebuild";
    preflight = "Validate a VPS configuration and SSH public keys";
  };
  commandPackages = lib.mapAttrs (command: _: pkgs.writeShellApplication {
    name = "vps-${command}";
    text = ''exec ${vps}/bin/vps ${command} "$@"'';
  }) commands;
in
{
  # Register each host and its user entry together.
  nixosConfigurations.vps = mkSystem {
    name = "vps";
    nixosModule = ../hosts/vps;
    homeModule = ../home/hosts/vps.nix;
  };

  formatter.${system} = pkgs.nixfmt;
  packages.${system} = commandPackages // {
    inherit vps;
    nixos-anywhere = pkgs.nixos-anywhere;
    default = commandPackages.install;
  };
  apps.${system} = lib.mapAttrs (command: description: {
    type = "app";
    program = "${commandPackages.${command}}/bin/vps-${command}";
    meta.description = description;
  }) commands;
  devShells.${system}.default = pkgs.mkShell {
    packages = scriptTools ++ (with pkgs; [ nixfmt statix deadnix shellcheck ]);
  };
  checks.${system} = {
    home = self.nixosConfigurations.vps.config.home-manager.users.${myvars.username}.home.activationPackage;
    shell = pkgs.runCommand "shellcheck" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
      shellcheck ${../scripts/vps.sh}
      touch $out
    '';
    policy =
      let c = self.nixosConfigurations.vps.config;
      in assert c.services.openssh.settings.PasswordAuthentication == false;
         assert c.services.openssh.settings.KbdInteractiveAuthentication == false;
         assert c.services.openssh.settings.PermitRootLogin == "no";
         assert c.networking.firewall.enable;
         assert lib.all (port: lib.elem port c.networking.firewall.allowedTCPPorts) c.services.openssh.ports;
         assert c.systemd.network.enable;
         assert !c.services.timesyncd.enable;
         assert !c.system.autoUpgrade.enable;
         assert c.services.fail2ban.enable;
         assert c.users.users.${myvars.username}.hashedPassword == "!";
         pkgs.writeText "vps-policy" "ok";
  };
}
