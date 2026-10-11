{ inputs, lib, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # 部署用 age 私钥保存在持久的 /nix 分区；不从 SSH 主机密钥派生。
  sops = {
    useSystemdActivation = true;
    age.keyFile = lib.mkDefault "/nix/var/lib/sops-nix/key.txt";
    age.sshKeyPaths = [ ];
    gnupg.sshKeyPaths = [ ];
  };
}
