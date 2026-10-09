{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.fleet.enable {
    environment.systemPackages = with pkgs; [
      # Editing, source control and structured data.
      git curl wget jq yq-go
      # File navigation, search and archives.
      ripgrep fd fzf bat eza tree less rsync unzip zip gnutar gzip xz zstd
      # Process, storage and network diagnostics.
      htop btop ncdu lsof file strace sysstat
      iproute2 iputils dnsutils mtr tcpdump nmap socat ethtool
      # System administration.
      openssh sudo pciutils usbutils util-linux nixos-rebuild
    ];

    programs.bash = {
      completion.enable = true;
      shellAliases = {
        ll = "eza -lah";
        gs = "git status --short --branch";
        v = "nvim";
        ports = "ss -tulpn";
        failed = "systemctl --failed";
      };
    };
    programs.tmux.enable = true;
    programs.neovim = {
      enable = true;
      defaultEditor = lib.mkDefault true;
    };
  };
}
