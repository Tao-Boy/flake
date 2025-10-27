{
  inputs,
  username,
  host,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
    ../../modules/cli/i18n.nix
    ../../modules/cli/nix.nix
    ../../modules/cli/packages.nix
    ../../modules/cli/user.nix
    ../../modules/cli/zram.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  wsl.enable = true;
  wsl.defaultUser = "${username}";

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs username host; };
    users.${username} = {
      imports = [
        #cli
        ../../home/cli/neovim
        ../../home/cli/btop.nix
        ../../home/cli/fastfetch.nix
        ../../home/cli/git.nix
        ../../home/cli/starship.nix
        ../../home/cli/yazi.nix
        ../../home/cli/zsh.nix
        #gui
        ../../home/gui/zathura.nix
      ];
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "25.11";
      programs.home-manager.enable = true;
    };
  };
}
