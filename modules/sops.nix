{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # 开机时用这把 age 私钥解密 secrets/ 中的文件，解密结果在内存中的 /run/secrets/。
  # 私钥不进入仓库，安装时单独复制到服务器（见 docs/deployment.md）。
  sops.age.keyFile = "/home/tau/.ssh/age.key";
  sops.age.sshKeyPaths = [ ]; # 只用上面的私钥
  sops.gnupg.sshKeyPaths = [ ];
}
