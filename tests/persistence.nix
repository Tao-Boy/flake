{ lib, users, ... }:
{
  # 安装测试借用 9p store，不修改共享 store 的所有权，也不创建用户 GC root。
  disko.tests.extraConfig = {
    nix.settings.build-users-group = lib.mkForce "";
    home-manager.users.${users.username}.home.activationGenerateGcRoot = lib.mkForce false;
  };
  disko.tests.extraChecks = ''
    machine.wait_for_unit("sshd.service")
    machine.wait_for_unit("home-manager-${users.username}.service")
    machine.succeed("findmnt / --types tmpfs")
    machine.succeed("findmnt /nix --types btrfs")
    machine.succeed("findmnt /home --types btrfs")
    machine.succeed("findmnt /boot --types vfat")
    machine.succeed("test $(id -u ${users.username}) = 1000")
    machine.succeed("touch /home/persistence-test /nix/var/persistence-test")
    machine.succeed("touch /etc/volatile-test /var/volatile-test /root/volatile-test")
    host_keys = machine.succeed("sha256sum /nix/var/lib/sshd/ssh_host_*_key")
    machine.reboot()
    machine.wait_for_shutdown()
    machine.start()
    machine.wait_for_unit("sshd.service")
    machine.wait_for_unit("home-manager-${users.username}.service")
    machine.succeed("findmnt / --types tmpfs")
    machine.succeed("findmnt /nix --types btrfs")
    machine.succeed("findmnt /home --types btrfs")
    machine.succeed("findmnt /boot --types vfat")
    machine.succeed("test -f /home/persistence-test && test -f /nix/var/persistence-test")
    machine.succeed("test ! -e /etc/volatile-test && test ! -e /var/volatile-test && test ! -e /root/volatile-test")
    assert machine.succeed("sha256sum /nix/var/lib/sshd/ssh_host_*_key") == host_keys
    machine.succeed("test $(id -u ${users.username}) = 1000")
  '';
}
