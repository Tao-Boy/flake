{
  inputs,
  users,
  machine,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs.pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${machine.system};
    users.${users.username} = machine.home;
  };
}
