{
  xz,
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  clang,
  binutils,
  ...
}:

let
  version = "0.5.511";
  sources = {
    x86_64-linux = {
      artifact = "perry-linux-x86_64.tar.gz";
      hash = "sha256-Falw2ShQMngLn0OjunPEs7SO5CbXzH+F7YxzuekwcmU=";
    };
    aarch64-linux = {
      artifact = "perry-linux-aarch64.tar.gz";
      hash = "sha256-ppg2DD943F8NvpZ+6G4EFDYoXUwTxSYR+y5ydcY3fPA=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "perry-bin: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "perry";
  inherit version;

  src = fetchurl {
    url = "https://github.com/PerryTS/perry/releases/download/v${version}/${source.artifact}";
    hash = source.hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    xz
  ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack

    mkdir source
    tar -xzf "$src" -C source
    cd source

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 perry "$out/bin/perry"

    mkdir -p "$out/lib/perry"

    for libfile in libperry_*.a; do
      if [ -f "$libfile" ]; then
        install -Dm444 "$libfile" "$out/lib/perry/$libfile"
      fi
    done

    wrapProgram "$out/bin/perry" \
      --prefix PATH : ${
        lib.makeBinPath [
          clang
          binutils
        ]
      } \
      --set-default PERRY_LLVM_CLANG "${clang}/bin/clang" \
      --set-default PERRY_RUNTIME_DIR "$out/lib/perry"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Native TypeScript compiler written in Rust, repackaged from the official Perry release tarball";
    homepage = "https://github.com/PerryTS/perry";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    mainProgram = "perry";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
