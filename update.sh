#!/usr/bin/env bash
# ============================================================
# nixpkgs 自动更新脚本
#
# 用法:
#   ./update.sh              # 更新所有可自动更新的包
#   ./update.sh ccline       # 只更新指定包
#   ./update.sh --check      # 只检查更新，不实际修改文件
#   ./update.sh --commit     # 更新后自动 git commit（Conventional Commits 格式）
#
# 依赖:
#   nix-update (>= 1.16.0)   # nix shell nixpkgs#nix-update
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

CHECK_ONLY=false
AUTO_COMMIT=false
TARGET=""

for arg in "$@"; do
  case "$arg" in
  --check) CHECK_ONLY=true ;;
  --commit) AUTO_COMMIT=true ;;
  *) TARGET="$arg" ;;
  esac
done

# 颜色输出
green() { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
cyan() { printf '\033[36m%s\033[0m\n' "$1"; }

# nix-update 基础参数（不使用 --commit，由本脚本控制 commit 格式）
NIX_UPDATE_FLAGS=("--flake")

# -----------------------------------------------------------
# 从 diff 中提取旧版本号和新版本号
# -----------------------------------------------------------
extract_versions() {
  local pkg_dir="$1"
  local old_ver="" new_ver=""

  # 查找 version = "..." 行（支持 stdenv.mkDerivation 和 let binding 两种模式）
  while IFS= read -r file; do
    # 旧版本：以 - 开头（被删除的行）
    old_ver=$(git diff "$file" | grep -E '^-\s*(version\s*=\s*)"' | head -1 | sed -E 's/^-\s*version\s*=\s*"([^"]*)".*/\1/')
    # 新版本：以 + 开头（新增的行）
    new_ver=$(git diff "$file" | grep -E '^\+\s*(version\s*=\s*)"' | head -1 | sed -E 's/^\+\s*version\s*=\s*"([^"]*)".*/\1/')

    if [[ -n "$old_ver" && -n "$new_ver" && "$old_ver" != "$new_ver" ]]; then
      printf '%s\n%s\n' "$old_ver" "$new_ver"
      return 0
    fi
  done < <(git diff --name-only -- "$pkg_dir")

  return 1
}

# -----------------------------------------------------------
# 按 Conventional Commits 格式提交
# -----------------------------------------------------------
commit_if_changed() {
  local pkg="$1"
  local pkg_dir="pkgs/${pkg}"

  # 对于 scripts 子目录的包做特殊处理
  if [[ ! -d "$pkg_dir" ]]; then
    pkg_dir="pkgs/scripts/${pkg}"
  fi

  if ! git diff --quiet -- "$pkg_dir"; then
    local versions
    versions=$(extract_versions "$pkg_dir") || true

    if [[ -n "$versions" ]]; then
      local old_ver new_ver
      old_ver=$(echo "$versions" | head -1)
      new_ver=$(echo "$versions" | tail -1)
      git add "$pkg_dir"
      git commit -m "chore(${pkg}): update ${old_ver} → ${new_ver}"
      green "  committed: chore(${pkg}): update ${old_ver} → ${new_ver}"
    else
      # 兜底：没能解析版本号时使用简单描述
      git add "$pkg_dir"
      git commit -m "chore(${pkg}): update to latest"
      green "  committed: chore(${pkg}): update to latest"
    fi
  fi
}

# -----------------------------------------------------------
# 执行 nix-update + 可选的 Conventional Commits commit
# -----------------------------------------------------------
run_nix_update() {
  local pkg="$1"
  shift
  local extra_flags=("$@")

  if nix-update "${NIX_UPDATE_FLAGS[@]}" "${extra_flags[@]}" "$pkg"; then
    if $AUTO_COMMIT && ! $CHECK_ONLY; then
      commit_if_changed "$pkg"
    fi
  else
    yellow "  $pkg 更新失败，跳过"
    return 1
  fi
}

# -----------------------------------------------------------
# 分类 1: 标准 GitHub Release 包
# -----------------------------------------------------------
update_github_release() {
  local pkg="$1"
  cyan ">>> 检查 $pkg (GitHub Release)..."
  if $CHECK_ONLY; then
    nix-update --flake "$pkg" --build 2>&1 | tail -3 || true
  else
    run_nix_update "$pkg"
  fi
}

# -----------------------------------------------------------
# 分类 2: Git 分支跟踪包（无 release tag）
# -----------------------------------------------------------
update_git_branch() {
  local pkg="$1"
  local branch="${2:-main}"
  cyan ">>> 检查 $pkg (Git branch=$branch)..."

  if $CHECK_ONLY; then
    nix-update --flake --version="branch=$branch" "$pkg" 2>&1 | tail -3 || true
  else
    run_nix_update "$pkg" --version="branch=$branch"
  fi
}

# -----------------------------------------------------------
# 分类 3: npm 包
# -----------------------------------------------------------
update_npm() {
  local pkg="$1"
  cyan ">>> 检查 $pkg (npm)..."
  if $CHECK_ONLY; then
    nix-update --flake "$pkg" 2>&1 | tail -3 || true
  else
    run_nix_update "$pkg"
  fi
}

# -----------------------------------------------------------
# 分类 4: 需手动更新的包（仅提示）
# -----------------------------------------------------------
manual_only() {
  local pkg="$1"
  local reason="$2"
  yellow ">>> 跳过 $pkg — $reason（需手动更新）"
}

echo ""
green "============================================"
green "  nixpkgs 包版本自动更新"
green "============================================"
echo ""

# --- 执行更新 ---

if [[ -z "$TARGET" ]] || [[ "$TARGET" == "ccline" ]]; then
  update_github_release "ccline"
fi

if [[ -z "$TARGET" ]] || [[ "$TARGET" == "cli-proxy-api" ]]; then
  update_github_release "cli-proxy-api"
fi

if [[ -z "$TARGET" ]] || [[ "$TARGET" == "perry" ]]; then
  update_github_release "perry"
fi

if [[ -z "$TARGET" ]] || [[ "$TARGET" == "kulala-core" ]]; then
  update_github_release "kulala-core"
fi

if [[ -z "$TARGET" ]] || [[ "$TARGET" == "kulala-fmt" ]]; then
  update_npm "kulala-fmt"
fi

if [[ -z "$TARGET" ]] || [[ "$TARGET" == "rime-ice" ]]; then
  update_git_branch "rime-ice" "main"
fi

if [[ -z "$TARGET" ]] || [[ "$TARGET" == "elegant-theme" ]]; then
  update_git_branch "elegant-theme" "main"
fi

# --- 需手动更新的包 ---
if [[ -z "$TARGET" ]]; then
  echo ""
  cyan "============================================"
  cyan "  以下包不支持自动更新，需手动操作"
  cyan "============================================"
  echo ""
  manual_only "apple-font-pingfang" "字体包，版本号嵌入在 release asset 名称中"
  manual_only "apple-font-pingfang-relaxed" "字体包，版本号嵌入在 release asset 名称中"
  manual_only "apple-font-pingfang-ui" "字体包，版本号嵌入在 release asset 名称中"
  manual_only "apple-font-pingfang-emoji" "字体包，上游发版节奏不规律"
  manual_only "wpsoffice" "WPS CDN 无公开 API，版本号嵌入 URL 路径"
  manual_only "ccs" "本地脚本，无需更新"
  manual_only "screenshot" "本地脚本，无需更新"
fi

echo ""
green "============================================"
green "  更新检查完成"
green "============================================"
echo ""

if $CHECK_ONLY; then
  cyan "提示: 以上为仅检查模式，未实际修改文件。"
  cyan "      去掉 --check 参数以执行实际更新。"
fi

