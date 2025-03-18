{
  self,
  nixpkgs,
  haumea,
  ...
} @ inputs: let
  inherit (nixpkgs) lib;
  vars = import ../vars;

  args = {inherit inputs lib vars;};

  data = haumea.lib.load {
    src = ../hosts;
    inputs = args;
  };

  dataWithoutPath = builtins.attrValues data;

  conf = lib.attrsets.mergeAttrsList dataWithoutPath;
in {
  nixosConfigurations = conf;
}
