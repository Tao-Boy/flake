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

    clang-tools
  ];
  environment.variables.EDITOR = "nvim";
}
