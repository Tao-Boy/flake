{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    zstd
    unzip
    gcc
    ripgrep
    gnumake

    alejandra
  ];
  environment.variables.EDITOR = "nvim";
}
