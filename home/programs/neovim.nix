{ pkgsUnstable, ... }:
{
  programs.neovim = {
    enable = true;
    package = pkgsUnstable.neovim-unwrapped;
    sideloadInitLua = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
