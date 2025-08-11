{
  inputs,
  pkgs,
  ...
}: {
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrains Nerd Font Mono";
      size = 12;
    };
    settings = {
      background_opacity = 0.75;
      background_blur = 1;
    };

    extraConfig = ''
      symbol_map U+4E00-U+9FFF,U+3400-U+4DBF,U+20000-U+2A6DF,U+2A700-U+2B73F,U+2B740-U+2B81F,U+2B820-U+2CEAF,U+F900-U+FAFF,U+2F800-U+2FA1F LXGW WenKai Mono
    '';
  };
}
