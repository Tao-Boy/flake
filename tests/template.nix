{ lib, ... }:
{
  # 仅供 CI 构建尚未填写的模板，产物不用于部署。
  config = lib.mkMerge [
    # 追加一把占位公钥，以通过管理员公钥断言。
    {
      local.admin.sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ci-placeholder"
      ];
    }
    # 仓库还没有加密的 Xray JSON 时，改用明文示例完成构建。
    (lib.mkIf (!builtins.pathExists ../secrets/xray.json) {
      local.proxy.configFile = lib.mkForce ../secrets/xray.example.json;
      sops.validateSopsFiles = false;
    })
  ];
}
