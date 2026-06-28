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
  version = "f8a8d41c8f306f8bdfae41db1a425cf0a2451477";
in
stdenv.mkDerivation {
  pname = "elegant-theme";
  inherit version;

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "Elegant-grub2-themes";
    rev = "${version}";
    hash = "sha256-4yPldMZ7g6FrGGvoF2oxvS6cGlM2X/ALX0mfq/Dax8c=";
  };
  installPhase = ''
    mkdir -p $out/grub/themes

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
