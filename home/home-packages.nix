{pkgs,...}:{
    home.packages = with pkgs; [
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