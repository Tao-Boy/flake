let
  gh-proxy = url: "git+https://gh.hitaoboy.top/github.com/" + url;
in {
  description = "Tao-Boy's NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    nixpkgs.url = gh-proxy "NixOS/nixpkgs?ref=nixos-unstable&shallow=1";
    nixos-hardware.url = gh-proxy "nixos/nixos-hardware?ref=master&shallow=1";

    home-manager = {
      url = gh-proxy "nix-community/home-manager?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = gh-proxy "nix-community/disko?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      type = "git";
      url = "https://gh.hitaoboy.top/github.com/hyprwm/Hyprland";
      submodules = true;
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
  in {
    nixosConfigurations = {
      pixelbook = nixpkgs.lib.nixosSystem {
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
