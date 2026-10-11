# 检查与运维

## 修改后验证

先填写真实 SSH 公钥，新增文件执行 `git add`。开发环境包含 nixfmt、sops、Xray 与安装器。

```bash
nix develop
nix fmt
nix flake check --no-build --no-write-lock-file   # 只求值，速度快
nix build --no-link .#nixosConfigurations.vps.config.system.build.toplevel
```

最后一条完整构建系统，包含 Home Manager 和 `proxy-off` 配置。CI 做两件事：检查 Nix 文件格式，构建 `.#checks.x86_64-linux.vps`。后者通过 `.github/ci.nix` 补上占位公钥并改用明文示例，因此仓库未填写时 CI 也能通过；产物不用于部署。CI 不连接 VPS、不写回仓库。

## 服务与网络

```bash
systemctl --failed
journalctl -b -p warning
systemctl status sshd fail2ban chronyd qemu-guest-agent
systemctl status xray sops-install-secrets
ls /run/current-system/specialisation/   # 存在 proxy-off 说明当前为默认配置
systemctl is-active xray
networkctl status
resolvectl status
ip -br address
ip route
ss -tulpn
sudo nft list ruleset
sudo fail2ban-client status sshd
systemctl status home-manager-tau.service
```

修改用户名后替换 Home Manager 服务名。DHCP / RA 应提供地址、路由、DNS；服务商只支持静态配置时应主动在机器入口声明。软件防火墙与服务商防火墙须同时允许 SSH 端口。

## 更新与回滚

```bash
nix flake update nixpkgs-unstable
nixos-rebuild test --flake .#vps --target-host tau@YOUR_SERVER --sudo
nixos-rebuild switch --flake .#vps --target-host tau@YOUR_SERVER --sudo
# 远端紧急回滚
sudo nixos-rebuild switch --rollback
```

也可通过服务商控制台从 GRUB 选择旧代际。GC 每周清理 14 天前的旧代际，GRUB 最多展示 10 个配置；已被 GC 删除的代际不能恢复。网络 / 公钥 / 端口变更先 `test` 并验证第二个会话。

## 状态与备份

```bash
findmnt /
findmnt /nix
findmnt /home
findmnt /boot
df -h
sudo systemctl status nix-gc.timer fstrim.timer
```

根 tmpfs 上限为内存的 50%，按需占用，并与应用、zram 共享物理内存；大型本机构建可将 Nix `build-dir` 指向 `/nix` 下专用目录。`/nix` 与 `/home` 使用独立 ext4 分区，分别检查可用空间并安排备份；空间不足时不能直接借用另一分区的空闲容量。

`/var` 默认易失，数据库、fail2ban 历史、rootful 容器和 ACME 证书需单独规划持久化。SSH 主机私钥和 age 私钥持久保存在 `/home/tau/.ssh`；备份须保留权限并按秘密处理。安装命令擦盘，日常更新只运行 `nixos-rebuild`。
