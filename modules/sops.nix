{ inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # 解密在 impermanence 挂载之前进行，因此直接读取 /nix/persist 中的文件。
  sops.age = {
    # 服务器上的 age 私钥，对应 .sops.yaml 中的 admin，是目前实际使用的解密密钥；缺失时激活失败。
    keyFile = "/nix/persist/home/tau/.config/sops/age/keys.txt";
    # 同时尝试 SSH 主机密钥（文件不存在只会警告）。把它的 ssh-to-age 公钥加入 .sops.yaml
    # 并执行 sops updatekeys 后，服务器即可不再保存上面的 age 私钥。
    sshKeyPaths = [ "/nix/persist/etc/ssh/ssh_host_ed25519_key" ];
    generateKey = false;
  };
}
