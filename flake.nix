{
  description = "Modular x86_64 NixOS VPS configuration with disko and nixos-anywhere";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, disko, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # An independent package set: the NixOS base is never overlaid with unstable.
      pkgsUnstable = nixpkgs-unstable.legacyPackages.${system};
      lib = nixpkgs.lib;
      hosts = import ./hosts;
      mkHost = name: hostModule: lib.nixosSystem {
        inherit system;
        specialArgs = { inherit pkgsUnstable; };
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
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
        install = { type = "app"; program = "${install}/bin/vps-install"; meta.description = "Install a VPS using nixos-anywhere with preflight and disk confirmation"; };
        rebuild = { type = "app"; program = "${rebuild}/bin/vps-rebuild"; meta.description = "Update a VPS using nixos-rebuild"; };
        preflight = { type = "app"; program = "${preflight}/bin/vps-preflight"; meta.description = "Validate a VPS configuration and its SSH public keys"; };
      };
      devShells.${system}.default = pkgs.mkShell {
        packages = scriptTools ++ (with pkgs; [ nixfmt statix deadnix shellcheck ]);
      };

      checks.${system} = {
        home =
          let c = self.nixosConfigurations.vps.config;
          in c.home-manager.users.${c.fleet.access.adminUser}.home.activationPackage;
        shell = pkgs.runCommand "shellcheck" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
          shellcheck ${./scripts/vps.sh}
          touch $out
        '';
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
