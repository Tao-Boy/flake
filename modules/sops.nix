{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # 只用 age 私钥解密 secrets/（对应 .sops.yaml 中的 admin），文件缺失时激活失败；不使用 SSH 主机密钥。
  # 解密在 impermanence 挂载之前进行，因此直接读取 /nix/persist 中的文件。
  sops.age = {
    keyFile = "/nix/persist/home/tau/.config/sops/age/keys.txt";
    sshKeyPaths = [ ];
    generateKey = false;
  };
}
