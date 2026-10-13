{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # 用 SSH 主机私钥解密 secrets/。解密早于 impermanence 挂载，因此直接读取持久化目录中的文件。
  sops.age = {
    keyFile = "/nix/persist/home/tau/.config/sops/age/keys.txt";
    sshKeyPaths = [ ];
    generateKey = false;
  };
}
