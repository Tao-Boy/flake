{
  description = "Tao-Boy's NixOS configuration";

  # nixConfig = {
  #   extra-substituters = [
  #     "https://hyprland.cachix.org"
  #   ];
  #   extra-trusted-public-keys = [
  #     "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
  #   ];
  # };

  inputs = {
    nixpkgs.url = "git+https://gh.hitaoboy.top/github.com/NixOS/nixpkgs?ref=nixos-unstable&shallow=1";
    nixos-hardware.url = "git+https://gh.hitaoboy.top/github.com/nixos/nixos-hardware?ref=master&shallow=1";

    home-manager = {
      url = "git+https://gh.hitaoboy.top/github.com/nix-community/home-manager?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "git+https://gh.hitaoboy.top/github.com/nix-community/disko?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hyprspace = {
    #   url = "git+https://gh.hitaoboy.top/github.com/KZDKM/Hyprspace?shallow=1";
    #   inputs.hyprland.follows = "hyprland";
    # };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    username = "tau";
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      pixelbook = nixpkgs.lib.nixosSystem {
        inherit system pkgs lib;
        modules = [./hosts/pixelbook];
        specialArgs = {
          host = "pixelbook";
          inherit inputs username;
        };
      };
    };
  };
}
