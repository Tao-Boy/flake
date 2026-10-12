{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops.age.keyFile = "/etc/ssh/ssh_host_ed25519_key";
}
