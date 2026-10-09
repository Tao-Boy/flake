{ ... }:
{
  imports = [
    ../../profiles/vps.nix
    ./hardware-configuration.nix
  ];

  # Only host-specific values belong here.
  fleet = {
    diskDevice = "/dev/vda"; # Check with lsblk; prefer /dev/disk/by-id/... when available.
    bootMode = "hybrid"; # "hybrid", "bios" or "uefi"; Secure Boot is not configured.
    access = {
      adminUser = "ops";
      sshPort = 22;
      # Add the COMPLETE contents of your .pub file before deploying.
      # Never add the private key to this repository.
      sshPublicKeys = [ ];
    };
    network = {
      # Pattern matches common virtio/e1000 interfaces. Verify using ip -br link.
      interface = "en* eth*";
      dhcp = true;
      acceptRA = true;
      dns = [ "1.1.1.1" "9.9.9.9" ];
    };
  };

  time.timeZone = "UTC";
  # Set when FIRST installing this host; do not bump merely to upgrade nixpkgs.
  system.stateVersion = "26.05";

  # Optional Podman:
  # fleet.containers.enable = true;
  #
  # Optional HTTPS reverse proxy: see docs/services.md.
  # services.nginx.enable = true;
}
