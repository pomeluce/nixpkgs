{
  stdenv,
  fetchurl,
  fontconfig,
  lib,
}:
stdenv.mkDerivation {
  pname = "ttf-pingfang-emoji";
  version = "18.4";

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-linux/releases/download/v18.4/AppleColorEmoji.ttf";
    sha256 = "1ggahpw54rjpxirjbyarwd5gvvg1hi08zw4c1nab8dqls5xhgzd4";
  };

  nativeBuildInputs = [ fontconfig ];

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/share/fonts/apple-color-emoji
    cp -r $src $out/share/fonts/apple-color-emoji/AppleColorEmoji.ttf

    # Install the fontconfig configuration
    mkdir -p $out/etc/fonts/conf.d
    cp -r ${./75-apple-color-emoji.conf} $out/etc/fonts/conf.d/
  '';

  meta = with lib; {
    description = "Apple Color Emoji is a color typeface used by iOS and macOS to display emoji";
    homepage = "https://github.com/samuelngs/apple-emoji-linux";
    license = licenses.unfree;
    maintainers = with maintainers; [ pomeluce ];
  };
}

