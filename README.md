# nixpkgs

个人 Nix 包集合 —— 自包含的 Nix flake，提供 overlay 和 packages 两种引入方式。

## 可用包

| 包名                          | 类型 | 描述                                             |
| ----------------------------- | ---- | ------------------------------------------------ |
| `apple-font-pingfang`         | 字体 | Apple 苹方 SC                                    |
| `apple-font-pingfang-relaxed` | 字体 | Apple 苹方 Relaxed                               |
| `apple-font-pingfang-ui`      | 字体 | Apple 苹方 UI                                    |
| `apple-font-pingfang-emoji`   | 字体 | Apple Color Emoji（含 fontconfig）               |
| `ccline`                      | CLI  | CCometixLine —— Rust 终端工具                    |
| `ccs`                         | CLI  | Claude Code Switcher —— 模型配置切换（Nushell）  |
| `cli-proxy-api`               | CLI  | CLIProxyAPI —— Go 服务端                         |
| `elegant-theme`               | 主题 | Elegant GRUB2 主题                               |
| `kulala-core`                 | CLI  | kulala —— Bun/TypeScript API 客户端              |
| `kulala-fmt`                  | CLI  | kulala-fmt —— Node.js 格式化工具                 |
| `perry`                       | CLI  | Perry TypeScript 编译器                          |
| `rime-ice`                    | 数据 | RIME 雾凇拼音输入方案                            |
| `screenshot`                  | CLI  | 截图工具（wayshot + wl-clipboard + notify-send） |
| `wpsoffice`                   | 应用 | WPS Office（deb 重打包）                         |

## 使用方式

### 方式一：作为 flake packages

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    apkgs ={
      url = "github:pomeluce/nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, apkgs }:
    let
      system = "x86_64-linux";
    in
    {
      # 直接引用
      packages.default = apkgs.packages.${system}.ccline;

      # 或在 devShell 中使用
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        packages = [
          apkgs.packages.${system}.kulala-fmt
          apkgs.packages.${system}.perry
        ];
      };
    };
}
```

命令行构建：

```sh
nix build github:pomeluce/nixpkgs#ccline
nix run github:pomeluce/nixpkgs#ccs
```

### 方式二：通过 overlay 混入 nixpkgs

```nix
# flake.nix — NixOS 或 home-manager 配置
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    apkgs ={
      url = "github:pomeluce/nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, apkgs, ... }:
    {
      nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ apkgs.overlays.default ];
            environment.systemPackages = [
              pkgs.ccline          # 直接用，如同 nixpkgs 原生包
              pkgs.cli-proxy-api
              pkgs.rime-ice
            ];
          })
        ];
      };
    };
}
```

### 方式三：本地开发

```nix
apkgs.url = "path:/home/user/dev/nixpkgs";
```

修改后运行 `nix flake lock --update-input apkgs` 刷新。

## 结构

```
nixpkgs/
├── flake.nix          # 入口：packages + overlays.default
├── pkgs/
│   ├── default.nix    # 包集定义，接受 { pkgs, ... }
│   ├── apple-font/    # 苹果字体四件套
│   ├── ccline/        # CCometixLine
│   ├── cli-proxy-api/ # CLIProxyAPI
│   ├── elegant-theme/ # GRUB2 主题
│   ├── kulala-core/   # kulala 核心
│   ├── kulala-fmt/    # kulala 格式化
│   ├── perry/         # Perry TS 编译器
│   ├── rime-ice/      # 雾凇拼音
│   ├── scripts/       # Nushell 脚本工具
│   └── wpsoffice/     # WPS Office
└── LICENSE
```

## 许可

GPL-3.0 — 详见 [LICENSE](./LICENSE)。各包上游许可证以其自身声明为准。

