{
  description = "Tao-Boy's NixOS configuration";
  inputs = {
    nixpkgs.url = "git+https://gh-proxy.hitaoboy.top/github.com/NixOS/nixpkgs?ref=nixos-unstable&shallow=1";
    nixos-hardware.url = "git+https://gh-proxy.hitaoboy.top/github.com/nixos/nixos-hardware?ref=master&shallow=1";

    home-manager = {
      url = "git+https://gh-proxy.hitaoboy.top/github.com/nix-community/home-manager?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "git+https://gh-proxy.hitaoboy.top/github.com/nix-community/disko?ref=master&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    haumea = {
      url = "git+https://gh-proxy.hitaoboy.top/github.com/nix-community/haumea?ref=main&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: import ./lib inputs;
}
