{ ... }:
{
  # Import this module only on hosts using Podman.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
}
