{ lib, myvars, ... }:
{
  users.mutableUsers = false;
  users.users.root.hashedPassword = "!";
  users.users.${myvars.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "!";
    openssh.authorizedKeys.keys = myvars.sshKeys;
  };
  security.sudo.wheelNeedsPassword = false;

  assertions = [{
    assertion = myvars.username != "root"
      && builtins.match "[a-z_][a-z0-9_-]*" myvars.username != null;
    message = "vars.username must be a normal Linux username other than root.";
  }];
  warnings = lib.optional (myvars.sshKeys == [ ])
    "Add SSH public keys in vars/default.nix before deploying this VPS.";
}
