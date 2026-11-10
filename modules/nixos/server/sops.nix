{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # 只用 age 私钥解密 secrets/（对应 .sops.yaml 中的 admin），文件缺失时激活失败；不使用 SSH 主机密钥。
  # 根文件系统持久化，因此直接读取用户家目录中的密钥。
  sops.age = {
    keyFile = "/home/tau/.config/sops/age/keys.txt";
    sshKeyPaths = [ ];
    generateKey = false;
  };
}
