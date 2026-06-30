{
  lib,
  stdenv,
  nodejs,
  kulala-core,
  fetchurl,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "kulala-fmt";
  version = "4.3.4";

  src = fetchurl {
    url = "https://registry.npmjs.org/@mistweaverco/kulala-fmt/-/kulala-fmt-${version}.tgz";
    hash = "sha256-29GRsjomms06D1VpqZ1pxfokSTDAsUCRNAnhYTDL/hI=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nodejs ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/kulala-fmt
    cp -r . $out/lib/node_modules/kulala-fmt

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/kulala-fmt \
      --add-flags "$out/lib/node_modules/kulala-fmt/dist/cli.cjs" \
      --set KULALA_CORE_PATH ${kulala-core}/bin/kulala-core

    runHook postInstall
  '';

  meta = {
    description = "Opinionated .http and .rest files linter and formatter";
    homepage = "https://github.com/mistweaverco/kulala-fmt";
    license = lib.licenses.mit;
    mainProgram = "kulala-fmt";
    platforms = lib.platforms.all;
  };
}
