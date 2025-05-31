{
  description = "Tao-Boy's NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks.url = "github:cachix/git-hooks.nix/master";

    disko = {
      url = "github:nix-community/disko/v1.11.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    self,
    ...
  } @ inputs: let
    username = "tau";
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      pixelbook = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/pixelbook
          (import ./overlays)
        ];
        specialArgs = {
          host = "pixelbook";
          inherit self inputs username;
        };
      };
    };
  };
}
