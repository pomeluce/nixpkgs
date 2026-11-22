{
  stdenv,
  lib,
  fetchFromGitHub,
  ...
}:

let
  version = "nightly-unstable-2026-11-11";
in
stdenv.mkDerivation {
  pname = "rime-ice";
  inherit version;

  src = fetchFromGitHub {
    owner = "iDvel";
    repo = "rime-ice";
    # version 是展示用的日期字符串, rev 才是实际 commit hash
    # nix-update --version=branch=main 会同时更新两者
    rev = "927e1cf1d3eeb9bf4be85e3f684dba4dd485b6f6";
    fetchSubmodules = true;
    hash = "sha256-laZ7u29e+F+2slf5td+rKbJuoFHCxUI928nJ+JimVNs=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/rime-data"
    cp -r * "$out/share/rime-data"

    install -Dm644 ${./default.custom.yaml} "$out/share/rime-data/default.custom.yaml"
    install -Dm644 ${./double_pinyin_flypy.custom.yaml} "$out/share/rime-data/double_pinyin_flypy.custom.yaml"

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/iDvel/rime-ice";
    description = "A long-term maintained simplified Chinese RIME schema";
    license = licenses.gpl3;
    platforms = platforms.all;
  };
}
