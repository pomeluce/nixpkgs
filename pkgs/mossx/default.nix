{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchPnpmDeps,
  cargo-tauri,
  cmake,
  desktop-file-utils,
  jq,
  nodejs_22,
  pnpm_10,
  pnpmConfigHook,
  pkg-config,
  wrapGAppsHook3,
  alsa-lib,
  glib-networking,
  gtk3,
  libgbm,
  libxkbcommon,
  openssl,
  pipewire,
  webkitgtk_4_1,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "mossx";
  version = "1.1.9";

  src = fetchFromGitHub {
    owner = "zhukunpenglinyutong";
    repo = "desktop-cc-gui";
    tag = "v${finalAttrs.version}";
    hash = "sha256-+R5XB7XvpKCiWSW8wzI9cnG74g/dicIhxZDLqSQqLsU=";
  };

  cargoHash = "sha256-d5RIQt4IZ5hAOoMEU4OkgTyeHoVyKds8mD1NgPNlD+o=";
  cargoRoot = "src-tauri";
  buildAndTestSubdir = "src-tauri";

  # The upstream ops_smoke example still calls async Git functions synchronously.
  doCheck = false;

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 3;
    pnpmInstallFlags = [ "--network-concurrency=4" ];
    hash = "sha256-sRtoMTsx7v1jCW3Teq4Aj/aNt6Bpd0rRbfSo33RN9+s=";
  };

  patches = [
    ./nix-managed-updates.patch
    ./frameless-linux.patch
  ];

  nativeBuildInputs = [
    cargo-tauri.hook
    rustPlatform.bindgenHook
    cmake
    desktop-file-utils
    jq
    nodejs_22
    pnpm_10
    pnpmConfigHook
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    glib-networking
    gtk3
    libgbm
    libxkbcommon
    openssl
    pipewire
    webkitgtk_4_1
  ];

  env = {
    OPENSSL_NO_VENDOR = "1";
    VITE_DISABLE_UPDATER = "1";
    VITE_FRAMELESS_WINDOW = "1";
  };

  postPatch = ''
    jq 'del(.plugins.updater) | .bundle.createUpdaterArtifacts = false | .build.beforeBuildCommand = "pnpm build"' \
      src-tauri/tauri.conf.json > src-tauri/tauri.conf.json.tmp
    mv src-tauri/tauri.conf.json.tmp src-tauri/tauri.conf.json
  '';

  postInstall = ''
    ln -s ccgui-next $out/bin/mossx
    mv "$out/share/applications/CC GUI.desktop" $out/share/applications/mossx.desktop
    desktop-file-edit \
      --set-name=mossx \
      --set-key=Exec --set-value=mossx \
      --set-key=Categories --set-value="Development;" \
      $out/share/applications/mossx.desktop
  '';

  preCheck = ''
    env -u VITE_DISABLE_UPDATER -u VITE_FRAMELESS_WINDOW pnpm run test:node
    # Too many jsdom workers make the 500-item history test exceed its 5s timeout.
    vitestWorkers=$((NIX_BUILD_CORES < 4 ? NIX_BUILD_CORES : 4))
    env -u VITE_DISABLE_UPDATER -u VITE_FRAMELESS_WINDOW pnpm exec vitest run \
      --minWorkers=1 --maxWorkers="$vitestWorkers" --reporter=dot
  '';

  meta = {
    description = "Multi-engine AI coding desktop client";
    homepage = "https://www.mossx.ai";
    changelog = "https://github.com/zhukunpenglinyutong/desktop-cc-gui/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    mainProgram = "mossx";
    platforms = [ "x86_64-linux" ];
  };
})
