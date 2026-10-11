{ inputs, lib, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];
  sops = {
    useSystemdActivation = true;
    age.keyFile = lib.mkDefault "/nix/var/lib/sops-nix/key.txt";
    age.sshKeyPaths = [ ];
    gnupg.sshKeyPaths = [ ];
  };
}
