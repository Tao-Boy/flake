{ pkgs, ... }:
{
  programs = {
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
  };
  home.packages = with pkgs; [
    #neovim lsp
    rime-ls
    lua-language-server
    texlab
    pyright
    #neovim formatter
    stylua
    nixfmt-classic
    rustfmt
    typstyle
    tex-fmt
    #texlive
    texliveFull
  ];
}
