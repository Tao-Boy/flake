{host, ...}: {
  imports = [
    ./cli
    (
      if host != "vps"
      then ./gui
      else []
    )
  ];
}
