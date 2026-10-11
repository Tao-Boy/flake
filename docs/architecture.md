# 配置结构与基本语法

## 三个入口

`flake.nix` 声明依赖和输出，直接将 `nixosConfigurations.vps` 指向 `machines/vps/`。机器目录中的 `default.nix` 选择系统模块，`home.nix` 选择用户软件；沿着这两个文件的 `imports` 就能找到实际配置。

| 位置 | 内容 |
| --- | --- |
| `flake.nix` | 依赖、机器入口、安装器、代理工具、格式化器、开发环境 |
| `flake.lock` | Nix 自动维护的依赖版本锁定文件 |
| `users.nix` | 系统与 Home Manager 共用的管理员身份、公钥 |
| `machines/<name>/` | 这台机器的系统选择、软件选择、硬件与磁盘 |
| `modules/nixos/` | 可供机器选择的系统配置 |
| `modules/home-manager.nix`、`disko.nix`、`sops.nix` | 接入对应外部模块 |
| `home/` | 全部用户软件与 dotfiles，公共兼容版本在 `default.nix` |
| `proxy/environment.nix`、`default.nix`、`setup.nix` | 本地代理地址、开关工具、密文与 LiveCD 初始化工具 |
| `secrets/xray.json` | 用户维护的整份加密 Xray JSON |

`flake.nix` 只负责连接入口。主机名、平台、时区和功能取舍在机器目录中声明。共用模块定义功能，由机器显式导入。

## 看懂常见写法

| 写法 | 含义 |
| --- | --- |
| `{ enable = true; }` | 属性集合；每项以分号结尾 |
| `[ ./base.nix ./ssh.nix ]` | 列表；元素用空格或换行分隔 |
| `{ pkgs, ... }: { ... }` | 接收 `pkgs` 等参数的函数；模块参数由 NixOS / Home Manager 提供 |
| `let pkgs = ...; in { ... }` | 为后面的表达式定义局部变量 |
| `import ./users.nix` | 读取并求值该 Nix 文件；导入目录时读取其 `default.nix` |
| `imports = [ ./base.nix ];` | 将其他模块加入当前配置 |
| `inherit inputs users;` | 等同于 `inputs = inputs; users = users;` |
| `specialArgs = { inherit inputs users; };` | 把这些值传给 NixOS 模块，供外部模块接入和账号配置使用 |
| `packages.${system}` | 以变量 `system` 的值作为属性名称 |
| `pkgs.callPackage ./proxy { }` | 调用该目录中的包定义，并自动提供它需要的 `pkgs`、`lib` 等参数 |
| `lib.mkDefault value` | 共享默认值；机器中的普通赋值可以覆盖它 |

例如，在 `machines/vps/default.nix` 写 `time.timeZone = "Asia/Shanghai";`；在 `machines/vps/home.nix` 的 imports 中加入 `../../home/programs/git.nix`，就会使用该文件中的 Git 设置。软件源中，`pkgs` 是稳定版，`pkgsUnstable` 是单独锁定的精选用户软件源。

## 接入关系

机器需要用户环境时，导入 `modules/home-manager.nix`，并将 `home-manager.users.${users.username}` 指向自己的 `home.nix`。接入文件加载 `home/default.nix` 的公共兼容版本并提供软件源；程序仍由机器选择。

机器的 `storage.nix` 选择共享存储布局，布局再导入 `modules/disko.nix`。Xray 服务模块导入 `modules/sops.nix`，将机器指定的加密 JSON 完整解密，由 systemd 直接启动 Xray 读取；Xray 选项由 JSON 维护。上游模块分别通过这些本地文件接入。

硬件文件始终从固定路径导入。用户保留适用模板、提供已有文件，或显式调用 nixos-anywhere 生成；求值和重建使用已保存的文件。

配置采用 NixOS / Home Manager 的原生选项与检查。`system.stateVersion` 和 `home.stateVersion` 表示首次安装时的兼容版本，升级输入时通常保持原值。

入门结构参考 [Misterio77/nix-starter-configs 的 minimal flake](https://github.com/Misterio77/nix-starter-configs/blob/main/minimal/flake.nix)；继续学习可参考 [Nix 语言基础](https://nix.dev/tutorials/nix-language) 和 [NixOS 模块](https://nix.dev/tutorials/module-system/module-system)。
