{pkgs, ...}: {
  imports = [
    ./audio.nix
    ./wayland.nix
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vaapiIntel
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };
}
