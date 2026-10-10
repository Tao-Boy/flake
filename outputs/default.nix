inputs:
let
  inherit (inputs.nixpkgs) lib;
  users = import ../users.nix;
  machines = import ../machines;
  mkSystem = import ../lib/nixos-system.nix { inherit inputs users; };
  nixosConfigurations = lib.mapAttrs mkSystem machines;
  # 工具所在平台与目标机器分开；当前部署工具仍只支持 x86_64-linux。
  forAllSystems = lib.genAttrs [ "x86_64-linux" ];
in
{
  inherit nixosConfigurations;
  packages = forAllSystems (
    system:
    import ./packages.nix {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    }
  );
  formatter = forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixfmt);
  devShells = forAllSystems (system: {
    default = import ./dev-shell.nix {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    };
  });
  checks = forAllSystems (
    system:
    import ../tests {
      inherit lib users nixosConfigurations;
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      source = inputs.self;
    }
  );
}
