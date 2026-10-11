{ lib, ... }:
{
  # 仅供 CI 构建：仓库还没填写公钥、没有密文时也能构建。产物不用于部署。
  users.users.tau.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ci-placeholder"
  ];
  # CI 不解密，只需要存在的文件代替尚未创建的密文（两个密文格式不同，需用不同文件）。
  sops.secrets."xray.json".sopsFile = lib.mkForce ../secrets/xray.example.json;
  sops.secrets.ssh_host_ed25519_key.sopsFile = lib.mkForce ./ci.nix;
  sops.validateSopsFiles = false;
}
