{
  inputs,
  username,
  ...
}:
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];
  environment.persistence."/nix/persistent" = {
    hideMounts = true;

    directories = [
      "/etc/NetworkManager/system-connections"
      "/root"
      "/var"
    ];

    files = [
      "/etc/machine-id"
    ];

    users.${username} = {
      directories = [
        "Desktop"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Projects"
        "Videos"

        ".cache/mesa_shader_cache"
        ".cache/nvim"
        ".config/flake"
        ".emacs.d"
        ".local/share/nvim"
        ".local/share/fcitx5"
        ".local/state/nvim"
        ".ssh"
      ];
      files = [
        ".zsh_history"
      ];
    };
  };
}
