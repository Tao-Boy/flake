{
  description = "x86_64 NixOS VPS with Home Manager and nixos-anywhere";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # 将软件源 inputs 传给 outputs/default.nix，由它定义主机和部署命令。
  outputs = inputs: import ./outputs/default.nix inputs;
}
