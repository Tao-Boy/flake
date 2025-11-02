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
  zen-browser = {
    url = "https://gh-proxy.com/github.com/0xc000022070/zen-browser-flake/archive/beta.tar.gz";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  niri = {
    url = "https://gh-proxy.com/github.com/sodiboo/niri-flake/archive/main.tar.gz";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  quickshell = {
      url = "https://gh-proxy.com/github.com/outfoxxed/quickshell/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "https://gh-proxy.com/github.com/noctalia-dev/noctalia-shell/archive/tag/v2.21.1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
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
        thinkbook = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            {nixpkgs.overlays = [
                emacs-overlay.overlays.default
              ];
            }
            ./hosts/thinkbook
          ];
          specialArgs = {
            inherit inputs username;
            host = "thinkbook";
          };
        };
      };
     };
}