{...}: {
  programs.fuzzel.enable = true;
  programs.fuzzel.settings = {
    main = {
      font = "Source Han Sans SC:size=18";
      terminal = "kitty -e";
      exit-on-keyboard-focus-loss = "yes";
      lines = 6;
      width = 20;
    };
    border = {
      radius = 30;
      width = 2;
    };
    colors = {
      background = "1e1e2edd";
      text = "cdd6f4ff";
      prompt = "bac2deff";
      placeholder = "7f849cff";
      input = "cdd6f4ff";
      match = "89b4faff";
      selection = "585b70ff";
      selection-text = "cdd6f4ff";
      selection-match = "89b4faff";
      counter = "7f849cff";
      border = "89b4faff";
    };
  };
}
