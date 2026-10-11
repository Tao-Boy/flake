{
  programs.bash.initExtra = ''
    eval "$(proxy env)"
    proxy-on() { sudo proxy on && eval "$(proxy env)"; }
    proxy-off() { sudo proxy off && eval "$(proxy env)"; }
  '';
}
