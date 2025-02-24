{
  description = "Tao-Boy's NixOS configuration";

  inputs = {
    nixpkgs.url = "git+https://gh.hitaoboy.top/github.com/NixOS/nixpkgs?ref=nixos-unstable&shallow=1";
    nixos-hardware.url = "git+https://gh.hitaoboy.top/github.com/nixos/nixos-hardware?shallow=1";

    home-manager = {
      url = "git+https://gh.hitaoboy.top/github.com/nix-community/home-manager?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "git+https://gh.hitaoboy.top/github.com/hyprwm/Hyprland?submodules=1&shallow=1";
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
  in {
    nixosConfigurations = {
      pixelbook = pkgs.lib.nixosSystem {
        inherit system;
        modules = [./hosts/pixelbook];
        specialArgs = {
          host = "pixelbook";
          inherit inputs username;
        };
      };
    };
  };
}
