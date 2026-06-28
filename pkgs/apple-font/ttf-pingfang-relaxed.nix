{
  stdenv,
  fetchurl,
  fontconfig,
  lib,
}:
stdenv.mkDerivation {
  pname = "ttf-pingfang-relaxed";
  version = "3.0.1";

  src = fetchurl {
    url = "https://github.com/witt-bit/applePingFangFonts/releases/download/3.0.1/pingFangRelaxed-19.0d5e3.tar.gz";
    sha256 = "cf1d3c696c6a73ea550b8f156caa7938ffd88bf5f99a558c71b6862f6be5e003";
  };

  nativeBuildInputs = [ fontconfig ];

  installPhase = ''
    mkdir -p $out/share/fonts/pingFangRelaxed
    cp -r * $out/share/fonts/pingFangRelaxed/
  '';

  meta = with lib; {
    description = "开苹方字体（PingFang Relaxed）";
    homepage = "https://developer.apple.com/fonts/";
    license = licenses.unfree;
    maintainers = with maintainers; [ pomeluce ];
  };
}

