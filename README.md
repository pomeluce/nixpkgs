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
├── update.sh          # 自动更新脚本
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

## 版本更新

### 自动更新（推荐）

使用 `update.sh` 脚本一键检查并更新所有可自动更新的包：

```sh
# 仅检查可用更新（不修改文件）
./update.sh --check

# 更新所有可自动更新的包
./update.sh

# 只更新指定包
./update.sh ccline

# 更新后自动 git commit（Conventional Commits 格式）
./update.sh --commit
```

`--commit` 会自动生成符合 [Conventional Commits](https://www.conventionalcommits.org) 规范的提交信息：

```
chore(perry): update 0.5.511 → 0.5.1182
chore(rime-ice): update 08e5594 → 6810e89
chore(kulala-core): update 0.25.0 → 0.26.0
```

脚本依赖 [`nix-update`](https://github.com/Mic92/nix-update)（≥ 1.16.0）：

```sh
nix shell nixpkgs#nix-update
```

### 更新策略概览

| 包名                 | 更新源                              | 自动化                                        |
| -------------------- | ----------------------------------- | --------------------------------------------- |
| `ccline`             | GitHub Release                      | ✅ `nix-update --flake`                       |
| `cli-proxy-api`      | GitHub Release（Go）                | ✅ `nix-update --flake`                       |
| `perry`              | GitHub Release（二进制）            | ✅ `nix-update --flake`                       |
| `kulala-core`        | GitHub Release                      | ✅ `nix-update --flake`                       |
| `kulala-fmt`         | npm registry                        | ✅ `nix-update --flake`                       |
| `rime-ice`           | Git main branch                     | ✅ `nix-update --flake --version=branch=main` |
| `elegant-theme`      | Git main branch                     | ✅ `nix-update --flake --version=branch=main` |
| `apple-font-*`       | GitHub Release（版本在 asset 名中） | ❌ 手动                                       |
| `wpsoffice`          | WPS CDN（无公开 API）               | ❌ 手动                                       |
| `ccs` / `screenshot` | 本地脚本                            | — 无需更新                                    |

### 手动更新字体包

```sh
# 1. 检查上游 release
#    https://github.com/witt-bit/applePingFangFonts/releases

# 2. 修改对应 .nix 文件中的 version 和 sha256
#    pkgs/apple-font/ttf-pingfang.nix

# 3. 获取新 hash
nix-build -A apple-font-pingfang 2>&1 | grep 'got:'
# 或
nix flake prefetch --json 2>&1
```

### 手动更新 WPS Office

```sh
# 1. 到 https://365.wps.cn 确认最新版本号
# 2. 修改 pkgs/wpsoffice/default.nix 中的 version
# 3. 将 hash 改为空字符串 "" 并运行构建获取新 hash
nix build --impure '.#wpsoffice' 2>&1 | grep 'got:'
```

## GitHub Actions 自动更新

仓库配置了两个 GitHub Actions 流水线，实现自动化更新和验证。

> **首次使用前**，需在 repo **Settings → Actions → General → Workflow permissions** 中：
>
> - 勾选 **"Allow GitHub Actions to create and approve pull requests"**
> - 将 **"Read and write permissions"** 设为默认

### 定时自动更新（`.github/workflows/update.yml`）

每天 UTC 6:00 自动执行，也可手动触发：

1. 运行 `./update.sh` 检测并应用更新
2. `nix flake check` 评估验证
3. `nix build` 对每个更新包执行构建，验证 hash 正确性
4. 通过后自动创建 PR（branch: `ci/auto-update`）

手动触发：GitHub → Actions → Auto Update → Run workflow，可指定 `package` 参数只更新单个包。

### PR 构建验证（`.github/workflows/build-check.yml`）

对任何修改 `pkgs/` 目录的 PR 自动执行：

1. `nix flake check` 评估所有 derivation
2. 找出 PR 涉及的包，逐个 `nix build` 验证

> **注意：** 字体包和 WPS Office（unfree license）在 CI 中跳过构建，需本地验证。

## 测试验证

> **`nix build` 和 `nix run` 不会安装任何东西到系统。**  
> 产物只写入 `/nix/store/` 并由 GC 管理，`build` 仅在当前目录创建一个 `result` 符号链接，`run` 临时执行后即退出。真正「安装」需要 `nix profile install` 或在 NixOS/home-manager 配置中声明。

### 快速检查（推荐每次更新后执行）

```sh
# 1. 评估所有包（确认 derivation 合法）
nix flake check

# 1b. 字体包有 unfree 许可证，需要：
NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure

# 2. 构建指定包
nix build '.#ccline'

# 3. 试运行 CLI 类包
nix run '.#ccline' -- --version
```

### 完整验证流程

每次更新版本后，建议按以下顺序验证：

```sh
# === 阶段 1: 评估 ===
# 确保所有 derivation 能正常求值
NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure

# === 阶段 2: 构建 ===
# 逐个构建包（首次或 hash 变更时需要下载依赖，耗时较长）
nix build '.#ccline'           # Rust 包，有 cargoHash
nix build '.#cli-proxy-api'    # Go 包，有 vendorHash
nix build '.#perry'            # 二进制重打包，较快
nix build '.#kulala-core'      # Bun/JS 包，有 node_modules FOD
nix build '.#kulala-fmt'       # npm 包
nix build '.#elegant-theme'    # GRUB 主题
nix build '.#rime-ice'         # RIME 数据包
nix build '.#wpsoffice'        # deb 重打包（需 --impure）
nix build '.#screenshot'       # Nushell 脚本
nix build '.#ccs'              # Nushell 脚本

# === 阶段 3: 功能验证 ===
# 对有 installCheck 的包（如 kulala-core），构建时自动运行：
nix build '.#kulala-core' --rebuild
# installCheck 会自动验证 curl 解析和 HTTP 请求生成

# 其他包手动验证：
nix run '.#ccline'                        # 检查状态栏输出
nix run '.#ccs' use-model                 # 检查模型切换
nix run '.#screenshot' -- --help           # 检查截图帮助
nix run '.#perry' -- --version            # 检查版本输出
nix run '.#cli-proxy-api' -- --help       # 检查帮助文本

# RIME 数据包验证安装内容：
nix build '.#rime-ice' --print-out-paths
ls "$(nix build '.#rime-ice' --print-out-paths --no-link)"/share/rime-data/

# GRUB 主题验证主题文件：
nix build '.#elegant-theme' --print-out-paths
ls "$(nix build '.#elegant-theme' --print-out-paths --no-link)"/grub/themes/

# === 阶段 4: 清理 ===
# 验证完成后清理构建缓存
nix store gc --dry-run    # 先看会删什么
nix store gc              # 实际清理
```

### 针对特定包类型的注意事项

**Go 包（`cli-proxy-api`）：**

- `vendorHash` 变化时需要更新：先用空字符串 `""` 替换 hash，构建失败后会输出正确 hash
- 如果上游修改了 `go.mod` 的 go 版本，检查 `postPatch` 是否仍需生效

**Rust 包（`ccline`）：**

- `cargoHash` 变化时同理，用空字符串构建获取新 hash

**Bun/JS 包（`kulala-core`）：**

- `node_modules` 的 `outputHash` 也需要更新：先构建 `kulala-core.node_modules` 获取新 hash

**二进制重打包（`perry`）：**

- 确认新版本的 artifact 文件名是否变化（`perry-linux-x86_64.tar.gz` 等）
- 每个平台的 hash 需分别更新

**字体包：**

- 字体文件较大（数百 MB），构建和下载耗时较长
- 只需检查文件是否正确安装到 `share/fonts/`

**WPS Office：**

- 上游 deb 包结构可能变化，注意 `installPhase` 中的路径修正 sed 是否仍然有效
- 构建需设置 `NIXPKGS_ALLOW_UNFREE=1`
