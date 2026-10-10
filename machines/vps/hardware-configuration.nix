{ modulesPath, ... }:
{
  # QEMU 模板，供初始配置使用；不执行硬件探测。
  # 用户可用 nixos-anywhere 的 nixos-generate-config 后端生成并替换本文件。
  # 文件系统由 storage.nix 管理，生成配置时不要重复声明挂载点。
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
}
