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

    emacs-overlay = {
      url = "https://gh-proxy.com/github.com/nix-community/emacs-overlay/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "https://gh-proxy.com/github.com/nix-community/impermanence/archive/master.tar.gz";
  
  nixos-wsl = {
    url = "https://gh-proxy.com/github.com/nix-community/NixOS-WSL/archive/main.tar.gz";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  };

  outputs =
    {
      nixpkgs,
      self,
      emacs-overlay,
      ...
    }@inputs:
    let
      username = "tau";
      system = "x86_64-linux";
      pkgs = import nixpkgs { 
        inherit system;
      };
      lib = nixpkgs.lib;
    in
      {
      nixosConfigurations = {
        nix-wsl = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            {nixpkgs.overlays = [
                emacs-overlay.overlays.default
              ];
            }
            ./hosts/wsl
          ];
          specialArgs = {
            host = "nix-wsl";
            inherit inputs username;
          };
        };
      };
     };
}