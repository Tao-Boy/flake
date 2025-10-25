{
  description = "Tao-Boy's NixOS configuration";
  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixpkgs-unstable";

    nixos-hardware.url = "git+https://github.com/NixOS/nixos-hardware?shallow=1&ref=master";

    home-manager = {
      url = "git+https://github.com/nix-community/home-manager?shallow=1&ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "git+https://github.com/nix-community/disko?shallow=1&tag=v1.12.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "git+https://github.com/nix-community/impermanence?shallow=1&ref=master";
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