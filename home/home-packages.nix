{pkgs,...}:{
    home.packages = with pkgs; [
    dconf
    #language servers
    texlab
    pyright
    #formatter
    stylua
    nixfmt
    rustfmt
    tex-fmt
    #texlive
    texliveFull
  ];
}