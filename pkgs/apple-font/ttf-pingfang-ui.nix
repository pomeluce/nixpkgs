{
  stdenv,
  fetchurl,
  lib,
}:
stdenv.mkDerivation {
  pname = "ttf-pingfang-ui";
  version = "3.0.1";

  src = fetchurl {
    url = "https://github.com/witt-bit/applePingFangFonts/releases/download/3.0.1/pingFangUI-20.0d15e3.tar.gz";
    sha256 = "1246b6a54ef7a0ddf1ce02da76d9ec9fcc03d948b7c6258dbeae93815e427f80";
  };

  installPhase = ''
    mkdir -p $out/share/fonts/pingFangUI
    cp -r * $out/share/fonts/pingFangUI/
  '';

  meta = with lib; {
    description = "苹方 UI 字体(PingFang UI)";
    homepage = "https://developer.apple.com/fonts/";
    license = licenses.unfree;
    maintainers = [ "pomeluce" ];
    platforms = platforms.all;
  };
}
