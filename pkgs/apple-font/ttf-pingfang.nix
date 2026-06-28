{
  stdenv,
  fetchurl,
  lib,
}:
stdenv.mkDerivation {
  pname = "ttf-pingfang";
  version = "3.0.1";

  src = fetchurl {
    url = "https://github.com/witt-bit/applePingFangFonts/releases/download/3.0.1/pingFang-20.0d4e1.tar.gz";
    sha256 = "0215ed14d69e3faecd3754ead14265d488b8fbea891a23ca1a93f7f5bdd02aa5";
  };

  installPhase = ''
    mkdir -p $out/share/fonts/pingFang
    cp -r * $out/share/fonts/pingFang/
  '';

  meta = with lib; {
    description = "Apple 公司苹方字体";
    homepage = "https://developer.apple.com/fonts/";
    license = licenses.unfree;
    maintainers = [ "pomeluce" ];
    platforms = platforms.all;
  };
}
