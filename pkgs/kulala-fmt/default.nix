{
  lib,
  stdenv,
  fetchurl,
  kulala-core,
  makeBinaryWrapper,
  nodejs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kulala-fmt";
  version = "4.5.3";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchurl {
    url = "https://registry.npmjs.org/@mistweaverco/kulala-fmt/-/kulala-fmt-${finalAttrs.version}.tgz";
    hash = "sha256-gT6fadmw8ej0sTPIZTshKbegoyjDYZwXWOcQRZL2Dnc=";
  };

  nativeBuildInputs = [ makeBinaryWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 dist/cli.cjs $out/lib/kulala-fmt/cli.cjs
    makeBinaryWrapper ${lib.getExe nodejs} $out/bin/kulala-fmt \
      --add-flags $out/lib/kulala-fmt/cli.cjs \
      --set KULALA_CORE_PATH ${lib.getExe kulala-core}

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/kulala-fmt --version | grep -x ${lib.escapeShellArg finalAttrs.version}
    printf '%s\n' 'GET https://example.com' | $out/bin/kulala-fmt format --stdin | grep 'GET https://example.com'

    runHook postInstallCheck
  '';

  meta = {
    description = "Opinionated .http and .rest files linter and formatter";
    homepage = "https://github.com/mistweaverco/kulala-fmt";
    license = lib.licenses.mit;
    mainProgram = "kulala-fmt";
    platforms = nodejs.meta.platforms;
  };
})
