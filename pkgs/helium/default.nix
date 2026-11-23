{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  binutils,
  patchelf,
  alsa-lib,
  alsa-plugins,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  coreutils,
  cups,
  dbus,
  expat,
  ffmpeg,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  gsettings-desktop-schemas,
  libGL,
  libICE,
  libSM,
  libX11,
  libXcomposite,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXft,
  libXi,
  libXrandr,
  libXrender,
  libXScrnSaver,
  libXt,
  libXtst,
  libasyncns,
  libdrm,
  libgbm,
  libkrb5,
  libuuid,
  libva,
  libxcb,
  libxkbcommon,
  libxml2,
  libxshmfence,
  makeFontsConf,
  nspr,
  nss,
  noto-fonts-cjk-sans,
  noto-fonts-cjk-serif,
  pango,
  pipewire,
  snappy,
  systemd,
  udev,
  vulkan-loader,
  wayland,
  xdg-utils,
  zlib,
  flags ? [ ],
  extraArgs ? [ ],
  desktopIntegration ? true,
}:
let
  pname = "helium";
  version = "0.22.2.1";

  architecture = {
    x86_64-linux = {
      suffix = "amd64";
      hash = "sha256-9AXe1VdIPUyuYID47PsGU+/IGjBHKPTwvRIOCeLlkfE=";
    };
    aarch64-linux = {
      suffix = "arm64";
      hash = "sha256-2nnloIli+Vv1ke9Oe8Fiy52jjP2EQtw9UJgtJP2b4ZY=";
    };
  };
  platform =
    architecture.${stdenv.hostPlatform.system}
      or (throw "Helium is not available on ${stdenv.hostPlatform.system}");

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-bin_${version}-1_${platform.suffix}.deb";
    inherit (platform) hash;
  };

  runtimeLibraries = [
    stdenv.cc.cc
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    ffmpeg
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libGL
    libICE
    libSM
    libX11
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXft
    libXi
    libXrandr
    libXrender
    libXScrnSaver
    libXt
    libXtst
    libasyncns
    libdrm
    libgbm
    libkrb5
    libuuid
    libva
    libxcb
    libxkbcommon
    libxml2
    libxshmfence
    nspr
    nss
    pango
    pipewire
    snappy
    systemd
    udev
    vulkan-loader
    wayland
    zlib
  ];

  libraryPath = lib.makeLibraryPath runtimeLibraries + ":" + placeholder "out" + "/opt/helium";
  outPath = placeholder "out";
  fontConfig = makeFontsConf {
    fontDirectories = [
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
    ];
  };

  shellArgs = lib.optionalString ((flags ++ extraArgs) != [ ]) (
    "set -- " + lib.concatStringsSep " " (map lib.escapeShellArg (flags ++ extraArgs)) + " \"$@\""
  );

  wrapper = lib.concatStringsSep "\n" (
    [
      "#!/bin/sh"
      "set -eu"
      ""
      "if [ -n \"\${NIXOS_OZONE_WL:-}\" ] && [ -n \"\${WAYLAND_DISPLAY:-}\" ]; then"
      "  set -- --ozone-platform-hint=auto \"$@\""
      "fi"
      ""
    ]
    ++ lib.optional (shellArgs != "") shellArgs
    ++ [
      "export LD_LIBRARY_PATH=\"${libraryPath}\${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\""
      "export ALSA_PLUGIN_DIR=\"${pipewire}/lib/alsa-lib:${alsa-plugins}/lib/alsa-lib\""
      "export FONTCONFIG_FILE=\"${fontConfig}\""
      "export CHROME_VERSION_EXTRA=\"nix\""
      "export GSETTINGS_SCHEMA_DIR=\"${gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${gsettings-desktop-schemas.version}/glib-2.0/schemas\""
      "export XDG_DATA_DIRS=\"${gtk3}/share:${gsettings-desktop-schemas}/share\${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}\""
      "export PATH=\"${
        lib.makeBinPath [
          coreutils
          xdg-utils
        ]
      }:$PATH\""
      "exec \"${outPath}/opt/helium/helium-wrapper\" \"$@\""
    ]
  );
in
stdenv.mkDerivation {
  inherit pname version src;

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  dontStrip = true;

  nativeBuildInputs = [
    binutils
    dpkg
    patchelf
  ];

  unpackPhase = ''
    runHook preUnpack
    ar x "$src"
    tar -xf data.tar.xz
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/opt" "$out/bin"
    cp -r opt/helium "$out/opt/helium"

    if ${lib.boolToString desktopIntegration}; then
      cp -r usr/share "$out/share"
      mkdir -p "$out/share/icons/hicolor/256x256/apps"
      if [ -f "$out/opt/helium/product_logo_256.png" ]; then
        cp "$out/opt/helium/product_logo_256.png" "$out/share/icons/hicolor/256x256/apps/helium.png"
      elif [ -f "$out/opt/helium/product_logo.png" ]; then
        cp "$out/opt/helium/product_logo.png" "$out/share/icons/hicolor/256x256/apps/helium.png"
      fi
    fi

    for binary in helium helium_crashpad_handler; do
      patchelf \
        --set-interpreter "$(cat "$NIX_CC/nix-support/dynamic-linker")" \
        --set-rpath "${libraryPath}" \
        "$out/opt/helium/$binary"
    done

    for library in "$out/opt/helium/libEGL.so" "$out/opt/helium/libGLESv2.so"; do
      if [ -f "$library" ]; then
        patchelf --set-rpath "${libraryPath}" "$library"
      fi
    done

    substituteInPlace "$out/opt/helium/helium-wrapper" \
      --replace-fail '$HERE/helium' "$out/opt/helium/helium"

    printf '%s' ${lib.escapeShellArg wrapper} > "$out/bin/helium"
    chmod +x "$out/bin/helium"

    if ${lib.boolToString desktopIntegration}; then
      substituteInPlace "$out/share/applications/helium.desktop" \
        --replace-fail 'Exec=helium' "Exec=$out/bin/helium" \
        --replace-fail 'Icon=helium' "Icon=$out/share/icons/hicolor/256x256/apps/helium.png"
    fi
    runHook postInstall
  '';

  meta = {
    homepage = "https://helium.computer";
    description = "Private, fast, and honest web browser based on Chromium";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "helium";
  };
}
