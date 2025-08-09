{
  username,
  pkgs,
  ...
}: {
  programs.mpvpaper = {
    enable = true;
    pauseList = ''
      google-chrome-stable
      obs
    '';
    stopList = ''
      google-chrome-stable
      obs
    '';
  };
}
