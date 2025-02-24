{
  description = "Tao-Boy's NixOS configuration";

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
  };

  inputs = {
    nixpkgs.url = "git+https://gh.hitaoboy.top/github.com/NixOS/nixpkgs?ref=nixos-unstable&shallow=1";
    nixos-hardware.url = "git+https://gh.hitaoboy.top/github.com/nixos/nixos-hardware?ref=master&shallow=1";

    home-manager = {
      url = "git+https://gh.hitaoboy.top/github.com/nix-community/home-manager?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "git+https://gh.hitaoboy.top/github.com/hyprwm/Hyprland?ref=main&submodules=1&shallow=1";
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
