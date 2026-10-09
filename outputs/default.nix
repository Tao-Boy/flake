{ self, nixpkgs, ... }@inputs:
let
  system = "x86_64-linux";
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
  mkCommand = command: pkgs.writeShellApplication {
    name = "vps-${command}";
    text = ''exec ${vps}/bin/vps ${command} "$@"'';
  };
  install = mkCommand "install";
  rebuild = mkCommand "rebuild";
  preflight = mkCommand "preflight";
in
{
  # Register each host and its user entry together.
  nixosConfigurations.vps = mkSystem {
    name = "vps";
    nixosModule = ../hosts/vps;
    homeModule = ../home/hosts/vps.nix;
  };

  formatter.${system} = pkgs.nixfmt;
  packages.${system} = {
    inherit vps install rebuild preflight;
    nixos-anywhere = pkgs.nixos-anywhere;
    default = install;
  };
  apps.${system} = {
    install = {
      type = "app";
      program = "${install}/bin/vps-install";
      meta.description = "Install a VPS with preflight and disk confirmation";
    };
    rebuild = {
      type = "app";
      program = "${rebuild}/bin/vps-rebuild";
      meta.description = "Update a VPS with nixos-rebuild";
    };
    preflight = {
      type = "app";
      program = "${preflight}/bin/vps-preflight";
      meta.description = "Validate a VPS configuration and SSH public keys";
    };
  };
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
         assert c.services.fail2ban.enable;
         assert c.users.users.${myvars.username}.hashedPassword == "!";
         pkgs.writeText "vps-policy" "ok";
  };
}
