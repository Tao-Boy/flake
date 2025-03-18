{hostName, ...}: {
  imports = [
    ./base
    (
      if hostName != "vm"
      then ./desktop
      else []
    )
  ];
}
