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
  python3,
  snappy,
  systemd,
  udev,
  vulkan-loader,
  wayland,
  writeText,
  xdg-utils,
  zlib,
  flags ? [ ],
  extraArgs ? [ ],
  desktopIntegration ? true,
  initialPrefs ? { },
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
    ++ lib.optional (profileSetupCommand != "") profileSetupCommand
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

  profileSetupScript = writeText "helium-profile-setup.py" ''
    import json
    import os
    import sys
    import tempfile
    from pathlib import Path


    def switch_value(args, name, default):
        for index, arg in enumerate(args):
            if arg.startswith(name + "="):
                return arg.split("=", 1)[1]
            if arg == name and index + 1 < len(args):
                return args[index + 1]
        return default


    def merge(target, defaults):
        for key, value in defaults.items():
            if isinstance(value, dict):
                if not isinstance(target.get(key), dict):
                    target[key] = {}
                merge(target[key], value)
            else:
                target[key] = value


    def read_json(path):
        if not path.exists():
            return {}
        data = json.loads(path.read_text())
        if not isinstance(data, dict):
            raise TypeError(f"Expected a JSON object in {path}")
        return data


    def write_json(path, data):
        path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as handle:
            temporary = Path(handle.name)
            try:
                json.dump(data, handle, ensure_ascii=False, separators=(",", ":"))
                handle.write("\n")
                handle.flush()
                os.fsync(handle.fileno())
                os.replace(temporary, path)
            finally:
                temporary.unlink(missing_ok=True)


    def configure(user_data, profile_name, defaults):
        if any((user_data / lock).exists() or (user_data / lock).is_symlink()
               for lock in ("SingletonLock", "SingletonCookie", "SingletonSocket")):
            return

        state_path = user_data / "Local State"
        state = read_json(state_path)
        if profile_name is None:
            profile_name = state.get("profile", {}).get("last_used", "Default")
        if Path(profile_name).name != profile_name or profile_name in (".", ".."):
            raise ValueError("Invalid profile directory")

        preferences_path = user_data / profile_name / "Preferences"
        preferences = read_json(preferences_path)
        previous_preferences = json.dumps(preferences, sort_keys=True)
        previous_state = json.dumps(state, sort_keys=True)
        merge(preferences, defaults)

        profile_defaults = defaults.get("profile")
        if isinstance(profile_defaults, dict) and "name" in profile_defaults:
            entry = state.get("profile", {}).get("info_cache", {}).get(profile_name)
            if isinstance(entry, dict):
                entry["name"] = profile_defaults["name"]
                entry["is_using_default_name"] = False

        if json.dumps(preferences, sort_keys=True) != previous_preferences:
            write_json(preferences_path, preferences)
        if json.dumps(state, sort_keys=True) != previous_state:
            write_json(state_path, state)


    def main():
        defaults = read_json(Path(sys.argv[1]))
        args = sys.argv[2:]
        if any(arg in ("--version", "--product-version", "--help") for arg in args):
            return

        config_home = os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))
        user_data = switch_value(args, "--user-data-dir", str(Path(config_home) / "helium"))
        profile_name = switch_value(args, "--profile-directory", None)
        try:
            configure(Path(user_data), profile_name, defaults)
        except (OSError, ValueError, TypeError, json.JSONDecodeError) as error:
            sys.exit(f"Cannot apply Helium preferences; existing profile data was preserved: {error}")


    if __name__ == "__main__":
        main()
  '';
  initialPrefsFile = writeText "helium-initial-prefs.json" (builtins.toJSON initialPrefs);
  profileSetupCommand = lib.optionalString (initialPrefs != { }) (
    "${python3}/bin/python ${outPath}/libexec/helium-profile-setup.py ${outPath}/share/helium/initial-prefs.json \"$@\""
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
    mkdir -p "$out/libexec"
    cp -r opt/helium "$out/opt/helium"

    if ${lib.boolToString desktopIntegration}; then
      cp -r usr/share "$out/share"
      mkdir -p "$out/share/icons/hicolor/256x256/apps"
      if [ -f "$out/opt/helium/product_logo_256.png" ]; then
        cp "$out/opt/helium/product_logo_256.png" "$out/share/icons/hicolor/256x256/apps/helium.png"
      elif [ -f "$out/opt/helium/product_logo.png" ]; then
        cp "$out/opt/helium/product_logo.png" "$out/share/icons/hicolor/256x256/apps/helium.png"
      fi
    else
      mkdir -p "$out/share"
    fi

    mkdir -p "$out/share/helium"
    cp "${profileSetupScript}" "$out/libexec/helium-profile-setup.py"
    cp "${initialPrefsFile}" "$out/share/helium/initial-prefs.json"
    chmod +x "$out/libexec/helium-profile-setup.py"

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
