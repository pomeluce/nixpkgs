{
  stdenv,
  lib,
  fetchFromGitHub,
  theme ? "mojave", # [forest|mojave|mountain|wave]
  screens ? "1080p", # [1080p|2k|4k]
  type ? "blur", # [window|float|sharp|blur]
  color ? "dark", # [dark|light]
  side ? "left", # [left|right]
  ...
}:
let
  version = "2025-03-25-unstable-2026-06-23";
in
stdenv.mkDerivation {
  pname = "elegant-theme";
  inherit version;

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "Elegant-grub2-themes";
    rev = "f8a8d41c8f306f8bdfae41db1a425cf0a2451477";
    hash = "sha256-4yPldMZ7g6FrGGvoF2oxvS6cGlM2X/ALX0mfq/Dax8c=";
  };
  installPhase = ''
    mkdir -p $out/grub/themes

    # generate.sh 期望 common/ 目录下存在 terminal_box_*.png 文件，
    # 但这些文件需要由主题资源脚本在运行时生成，构建时仅需占位。
    # 此处创建空文件以满足脚本的存在性检查，实际图标随后由 generate.sh 生成替换。
    mkdir -p common
    for box in c e n ne nw s se sw w; do
      touch common/terminal_box_$box.png
    done

    # Run the install script
              bash ./generate.sh \
                --dest $out/grub/themes \
                --theme ${theme} \
                --screen ${screens} \
                --color ${color} \
                --type ${type} \
                --side ${side} \
  '';

  meta = with lib; {
    description = "Elegant grub2 themes for all linux systems";
    homepage = "https://github.com/vinceliuice/Elegant-grub2-themes";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
