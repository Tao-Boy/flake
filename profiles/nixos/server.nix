{
  imports = [
    ./base.nix
    ../../modules/nixos/networking/default.nix
    ../../modules/nixos/security/ssh.nix
    ../../modules/nixos/security/hardening.nix
    ../../modules/nixos/services/maintenance.nix
  ];
}
