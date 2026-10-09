{
  description = "Modular x86_64 NixOS VPS configuration with disko and nixos-anywhere";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    disko = {
      url = "github:nix-community/disko/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;
      hosts = import ./hosts;
      mkHost = name: hostModule: lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./modules
          hostModule
          { networking.hostName = lib.mkDefault name; }
        ];
      };
      scriptTools = with pkgs; [
        bash coreutils git jq openssh nix nixos-anywhere nixos-rebuild
      ];
      vps = pkgs.writeShellApplication {
        name = "vps";
        runtimeInputs = scriptTools;
        text = builtins.readFile ./scripts/vps.sh;
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
      nixosConfigurations = lib.mapAttrs mkHost hosts;

      nixosModules = {
        default = ./modules;
        vps = ./profiles/vps.nix;
      };

      formatter.${system} = pkgs.nixfmt;
      packages.${system} = {
        inherit vps install rebuild preflight;
        nixos-anywhere = pkgs.nixos-anywhere;
        default = install;
      };
      apps.${system} = {
        install = { type = "app"; program = "${install}/bin/vps-install"; };
        rebuild = { type = "app"; program = "${rebuild}/bin/vps-rebuild"; };
        preflight = { type = "app"; program = "${preflight}/bin/vps-preflight"; };
      };
      devShells.${system}.default = pkgs.mkShell {
        packages = scriptTools ++ (with pkgs; [ nixfmt statix deadnix shellcheck ]);
      };

      checks.${system} = {
        shell = pkgs.runCommand "shellcheck" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
          shellcheck ${./scripts/vps.sh}
          touch $out
        '';
        # Force evaluation of all host toplevels without building each closure.
        evaluation = pkgs.writeText "host-derivations.json" (builtins.toJSON (
          lib.mapAttrs (_: host: host.config.system.build.toplevel.drvPath)
            self.nixosConfigurations
        ));
        policy =
          let c = self.nixosConfigurations.vps.config;
          in assert c.services.openssh.settings.PasswordAuthentication == false;
             assert c.services.openssh.settings.KbdInteractiveAuthentication == false;
             assert c.services.openssh.settings.PermitRootLogin == "no";
             assert c.networking.firewall.enable;
             assert c.services.fail2ban.enable;
             assert c.users.users.${c.fleet.access.adminUser}.hashedPassword == "!";
             pkgs.writeText "vps-policy" "ok";
      };
    };
}
