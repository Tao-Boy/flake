{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    google-chrome
  ];
}
