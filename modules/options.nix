{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.fleet;
in
{
  options.fleet = {
    enable = mkEnableOption "the VPS baseline";
    diskDevice = mkOption {
      type = types.str;
      default = "/dev/vda";
      description = "Whole installation disk; ALL existing contents will be destroyed.";
    };
    bootMode = mkOption {
      type = types.enum [ "hybrid" "bios" "uefi" ];
      default = "hybrid";
      description = "GRUB installation mode on x86_64.";
    };
    access = {
      adminUser = mkOption {
        type = types.str;
        default = "ops";
        description = "SSH administration account with passwordless sudo.";
      };
      sshPort = mkOption {
        type = types.port;
        default = 22;
        description = "SSH port after installation.";
      };
      sshPublicKeys = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Complete OpenSSH public keys. Deployment scripts refuse an empty list.";
      };
    };
    network = {
      interface = mkOption {
        type = types.str;
        default = "en* eth*";
        description = "systemd-networkd interface name/pattern; use an exact name with static networking.";
      };
      dhcp = mkOption { type = types.bool; default = true; };
      acceptRA = mkOption { type = types.bool; default = true; };
      addresses = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "192.0.2.10/24" "2001:db8::10/64" ];
        description = "Static IP addresses in CIDR notation; obtain actual values from your provider.";
      };
      gateway4 = mkOption { type = types.nullOr types.str; default = null; };
      gateway6 = mkOption { type = types.nullOr types.str; default = null; };
      dns = mkOption {
        type = types.listOf types.str;
        default = [ "1.1.1.1" "9.9.9.9" ];
      };
    };
    containers.enable = mkEnableOption "Podman and Docker-compatible CLI";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/dev/" cfg.diskDevice;
        message = "fleet.diskDevice must be a whole disk path under /dev/.";
      }
      {
        assertion = builtins.match "[a-z_][a-z0-9_-]*" cfg.access.adminUser != null
          && cfg.access.adminUser != "root";
        message = "fleet.access.adminUser must be a normal Linux username other than root.";
      }
      {
        assertion = cfg.network.dhcp || cfg.network.addresses != [ ];
        message = "Static networking requires fleet.network.addresses.";
      }
      {
        assertion = cfg.network.dhcp
          || builtins.match ".*[?* ].*" cfg.network.interface == null;
        message = "Use an exact fleet.network.interface name for static networking.";
      }
    ];
    warnings = lib.optional (cfg.access.sshPublicKeys == [ ])
      "VPS template has no SSH public keys. Add fleet.access.sshPublicKeys before installation; password and root logins are disabled.";
  };
}
