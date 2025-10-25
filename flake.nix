{
  description = "Tao-Boy's NixOS configuration";
  inputs = {
    nixpkgs.url = "https://gh-proxy.com/github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz";

    nixos-hardware.url = "https://gh-proxy.com/github.com/NixOS/nixos-hardware/archive/master.tar.gz";

    home-manager = {
      url = "https://gh-proxy.com/github.com/nix-community/home-manager/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "https://gh-proxy.com/github.com/nix-community/disko/archive/v1.12.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "https://gh-proxy.com/github.com/nix-community/impermanence/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      self,
      ...
    }@inputs:
    let
      username = "tau";
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations = {
        thinkbook = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/thinkbook
            (import ./overlays)
          ];
          specialArgs = {
            host = "thinkbook";
            inherit inputs username;
          };
        };
      };
};
}