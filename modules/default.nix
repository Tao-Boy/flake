{host, ...}: {
  imports = [
    ./cli
    (
      if host != "vm"
      then ./gui
      else []
    )
  ];
}
