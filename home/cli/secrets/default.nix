{
  inputs,
  username,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.file = {
    "id_ed25519.pub" = {
      source = ./id_ed25519.pub;
      target = ".ssh/id_ed25519.pub";
    };
  };

  sops = {
    age.keyFile = "/home/${username}/.config/age/keys.txt";
    defaultSopsFile = ./.sops.yaml;

    secrets = {
      id_ed25519 = {
        format = "binary";
        sopsFile = ./id_ed25519;
        path = "/home/${username}/.ssh/id_ed25519";
      };
    };
  };
}
