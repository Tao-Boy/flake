# inputs 包含 flake.nix 中声明的软件源。
inputs:
let
  # 部署工具使用稳定源；本仓库只支持 x86_64-linux。
  pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
  myvars = import ../vars/default.nix;

  # 添加主机时，复制这段并修改名称、系统入口和用户入口。
  vpsSystem = import ../lib/nixos-system.nix {
    inputs = inputs;
    myvars = myvars;
    name = "vps";
    nixosModule = ../hosts/vps/default.nix;
    homeModule = ../home/hosts/vps.nix;
  };
  vpsConfig = vpsSystem.config;

  # 统一部署脚本。runtimeInputs 为脚本提供运行时所需的命令。
  vps = pkgs.writeShellApplication {
    name = "vps";
    meta.mainProgram = "vps";
    runtimeInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.git
      pkgs.jq
      pkgs.openssh
      pkgs.nix
      pkgs.nixos-anywhere
      pkgs.nixos-rebuild
    ];
    text = builtins.readFile ../scripts/vps.sh;
  };

  # 三个包装命令分别声明；"$@" 原样传递终端中的参数。
  install = pkgs.writeShellApplication {
    name = "vps-install";
    meta.mainProgram = "vps-install";
    text = ''
      exec ${vps}/bin/vps install "$@"
    '';
  };

  rebuild = pkgs.writeShellApplication {
    name = "vps-rebuild";
    meta.mainProgram = "vps-rebuild";
    text = ''
      exec ${vps}/bin/vps rebuild "$@"
    '';
  };

  preflight = pkgs.writeShellApplication {
    name = "vps-preflight";
    meta.mainProgram = "vps-preflight";
    text = ''
      exec ${vps}/bin/vps preflight "$@"
    '';
  };

  # 检查用的小函数：某个 SSH 端口是否在防火墙允许列表中。
  sshPortIsOpen = port: builtins.elem port vpsConfig.networking.firewall.allowedTCPPorts;
in
{
  nixosConfigurations.vps = vpsSystem;

  formatter."x86_64-linux" = pkgs.nixfmt;

  # 这些软件包既能 nix build，也能通过 meta.mainProgram 被 nix run 运行。
  packages."x86_64-linux" = {
    vps = vps;
    install = install;
    rebuild = rebuild;
    preflight = preflight;
    nixos-anywhere = pkgs.nixos-anywhere;
    default = install;
  };

  # nix develop 使用的本地开发工具。
  devShells."x86_64-linux".default = pkgs.mkShell {
    packages = [
      pkgs.bash
      pkgs.coreutils
      pkgs.git
      pkgs.jq
      pkgs.openssh
      pkgs.nix
      pkgs.nixos-anywhere
      pkgs.nixos-rebuild
      pkgs.nixfmt
      pkgs.statix
      pkgs.deadnix
      pkgs.shellcheck
    ];
  };

  # nix flake check 使用的三个检查项。
  checks."x86_64-linux" = {
    # 构建用户环境；用户名来自 vars/default.nix。
    home = vpsConfig.home-manager.users.${myvars.username}.home.activationPackage;

    # 构建此检查时运行 ShellCheck；$out 是构建结果的路径。
    shell = pkgs.runCommand "shellcheck" {
      nativeBuildInputs = [ pkgs.shellcheck ];
    } ''
      shellcheck ${../scripts/vps.sh}
      touch $out
    '';

    # 求值时逐项验证配置，通过后生成内容为 ok 的检查结果。
    # 公钥非空的登录保护由 NixOS 用户模块执行；格式由部署预检验证。
    policy =
      assert vpsConfig.services.openssh.settings.PasswordAuthentication == false;
      assert vpsConfig.services.openssh.settings.KbdInteractiveAuthentication == false;
      assert vpsConfig.services.openssh.settings.PermitRootLogin == "no";
      assert vpsConfig.networking.firewall.enable;
      assert builtins.all sshPortIsOpen vpsConfig.services.openssh.ports;
      assert vpsConfig.systemd.network.enable;
      assert vpsConfig.services.timesyncd.enable == false;
      assert vpsConfig.system.autoUpgrade.enable == false;
      assert vpsConfig.services.fail2ban.enable;
      assert vpsConfig.users.users.${myvars.username}.hashedPassword == "!";
      pkgs.writeText "vps-policy" "ok";
  };
}
