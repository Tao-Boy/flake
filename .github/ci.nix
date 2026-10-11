{ lib, ... }:
{
  # 仅供 CI 构建：仓库还没填写公钥、没有密文时也能构建。产物不用于部署。
  users.users.tau.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ci-placeholder"
  ];
  sops.secrets."xray.json".sopsFile = lib.mkForce ../secrets/xray.example.json;
  sops.validateSopsFiles = false;
}
