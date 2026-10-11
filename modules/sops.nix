{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # 开机时用这把 age 私钥解密 secrets/ 中的文件，解密结果在内存中的 /run/secrets/。
  # 私钥由用户自己保存，不进入仓库；放在用户目录下 sops 的默认位置（见 docs/deployment.md）。
  sops.age.keyFile = "/home/tau/.config/sops/age/keys.txt";
  sops.age.sshKeyPaths = [ ]; # 只用上面的私钥
  sops.gnupg.sshKeyPaths = [ ];
}
