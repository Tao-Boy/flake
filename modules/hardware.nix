{inputs, ...}: {
  imports = [
    inputs.nixos-hardware.nixosModules.google-pixelbook
  ];
}
