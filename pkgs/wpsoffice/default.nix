{
  lib,
  stdenv,
  makeWrapper,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  alsa-lib,
  at-spi2-core,
  libtool,
  libxkbcommon,
  nspr,
  mesa,
  libtiff,
  udev,
  gtk3,
  qtbase,
  libXdamage,
  libXtst,
  libXv,
  libXScrnSaver,
  libxcb,
  libX11,
  libXrender,
  libSM,
  libICE,
  libXcursor,
  cups,
  pango,
  freetype,
  libjpeg,
  libpulseaudio,
  fcitx5-qt,
  libbsd,
  libusb1,
  libmysqlclient,
  fontconfig,
  glib,
  libuuid,
  libglvnd,
  cairo,
  gdk-pixbuf,
}:
let
  libs = [
    stdenv.cc.cc
    stdenv.cc.libc
    stdenv.cc.cc.lib
    alsa-lib
    at-spi2-core
    libtool
    libxkbcommon
    nspr
    mesa
    udev
    gtk3
    qtbase
    libXdamage
    libXtst
    libXv
    libXScrnSaver
    libxcb
    libX11
    libXrender
    libSM
    libICE
    libXcursor
    cups
    pango
    libpulseaudio
    libjpeg
    freetype
    fcitx5-qt
    libbsd
    libusb1
    libmysqlclient
    fontconfig
    glib
    libuuid
    libglvnd
    cairo
    gdk-pixbuf
    libtiff
  ];
in
stdenv.mkDerivation rec {
  pname = "wpsoffice";
  # version = "12.1.2.22550";
  version = "12.8.2.21176";

  src = fetchurl {
    url = "https://pubwps-wps365-obs.wpscdn.cn/download/Linux/${lib.last (builtins.splitVersion version)}/wps-office_${version}.AK.preload.sw_amd64.deb";
    # hash = "sha256-LfRIgej0kAafsfOE/0Jt6OJxv7802vCgu7GKVUFqbHA=";
    hash = "sha256-kcxZ5ySWYpBJ7a8bNfp9ho4vWPZaVz2fcN+5HwQoGyw=";
  };

  unpackCmd = " dpkg -x $src .";
  sourceRoot = ".";

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  preBuild = ''
    addAutoPatchelfSearchPath ${libmysqlclient}/lib/mariadb/
  '';

  buildInputs = libs;

  dontWrapQtApps = true;

  autoPatchelfIgnoreMissingDeps = [
    "libpeony.so.3"
    "libcaja-extension.so.1"
  ];

  installPhase = ''
    ls .
    runHook preInstall
    prefix=$out/opt/kingsoft/wps-office
    mkdir -p $out/opt/kingsoft/wps-office
    find usr -name '*xiezuo*' -exec rm -rf {} +
    find usr -name '*uninstall.desktop' -exec rm -rf {} +
    rm -rf opt/xiezuo/
    rm -rf usr/share/desktop-directories
    cp -r opt/kingsoft/wps-office/office6 $out/opt/kingsoft/wps-office/office6
    cp -r usr/* $out

    # use system lib
    rm $out/opt/kingsoft/wps-office/office6/lib{jpeg,stdc++}.so*

    # fix template path
    sed -i 's|URL=.*|URL=/opt/kingsoft/wps-office/office6/mui/zh_CN/templates/newfile.docx|' $out/share/templates/wps-office-wps-template.desktop
    sed -i 's|URL=.*|URL=/opt/kingsoft/wps-office/office6/mui/zh_CN/templates/newfile.xlsx|' $out/share/templates/wps-office-et-template.desktop
    sed -i 's|URL=.*|URL=/opt/kingsoft/wps-office/office6/mui/zh_CN/templates/newfile.pptx|' $out/share/templates/wps-office-wpp-template.desktop

    # fix menu category
    sed -i 's|Categories=.*|&Office;|' $out/share/applications/*.desktop

    # fix background process
    sed -i '2i [[ $(ps -ef | grep -c "office6/$(basename $0)") == 1 ]] && export gOptExt=-multiply' $out/bin/{wps,wpp,et,wpspdf}

    # fix input method
    sed -i '2i [[ "$XMODIFIERS" == "@im=fcitx" ]] && export QT_IM_MODULE=fcitx' $out/bin/{wps,wpp,et,wpspdf}

    # allow custom fontconfig
    sed -i '2i [[ -f ~/.config/Kingsoft/fonts/fonts.conf ]] && export FONTCONFIG_FILE=~/.config/Kingsoft/fonts/fonts.conf' usr/bin/{wps,wpp,et,wpspdf}

    # Fix /bin path
    ## wps, wpp, et, wpspdf, misc, wpsclouddisk
    for i in wps wpp et wpspdf misc wpsclouddisk; do
      substituteInPlace $out/bin/$i --replace-warn /opt/kingsoft/wps-office $prefix
    done
    # quickstartoffice
    substituteInPlace $out/bin/quickstartoffice --replace-warn /opt/kingsoft/wps-office $prefix
    substituteInPlace $out/bin/quickstartoffice --replace-warn /usr/bin $out/bin
    # wpsprint
    sed -i "2i export PATH=$out/bin:$PATH" $out/bin/wpsprint

    # Fix DesktopFile path
    for i in $out/share/applications/*;do
      substituteInPlace $i --replace-warn /usr/bin $out/bin
    done

    # set ENV
    sed -i "2i unset WAYLAND_DISPLAY && export LD_LIBRARY_PATH=${lib.makeLibraryPath libs} && export QT_QPA_PLATFORM=xcb" $out/bin/{wps,wpp,et,wpspdf,misc,wpsclouddisk}

    runHook postInstall
  '';

  preFixup = ''
    patchelf --replace-needed libmysqlclient.so.18 libmysqlclient.so $out/opt/kingsoft/wps-office/office6/libFontWatermark.so
  '';

  meta = with lib; {
    description = "WPS Office, is an office productivity suite.";
    homepage = "https://365.wps.cn";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfreeRedistributable;
    maintainers = with maintainers; [ pomeluce ];
  };
}
