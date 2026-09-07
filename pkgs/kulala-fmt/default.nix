{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  kulala-core,
  makeBinaryWrapper,
  nodejs,
  pnpm_11,
  pnpmConfigHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kulala-fmt";
  version = "4.5.3";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "mistweaverco";
    repo = "kulala-fmt";
    tag = "v${finalAttrs.version}";
    hash = "sha256-POxmVHq/vjRr0I8ropRr5Vs021yLdmZz9UvrHM/zRIc=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_11;
    fetcherVersion = 4;
    hash = "sha256-UQA6uy4URImcV9HHMjstU8scWeJ0kNfa4tQdwcYxsG0=";
  };

  nativeBuildInputs = [
    makeBinaryWrapper
    nodejs
    pnpm_11
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild

    pnpm run build

    runHook postBuild
  '';

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
