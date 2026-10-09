{ pkgsUnstable, ... }:
{
  programs.neovim = {
    enable = true;
    package = pkgsUnstable.neovim-unwrapped;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # Keep the VPS editor small; enable language providers when needed.
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
  };
}
