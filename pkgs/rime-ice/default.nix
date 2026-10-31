{
  stdenv,
  lib,
  fetchFromGitHub,
  ...
}:

let
  version = "nightly-unstable-2026-10-31";
in
stdenv.mkDerivation {
  pname = "rime-ice";
  inherit version;

  src = fetchFromGitHub {
    owner = "iDvel";
    repo = "rime-ice";
    # version 是展示用的日期字符串, rev 才是实际 commit hash
    # nix-update --version=branch=main 会同时更新两者
    rev = "d7f7ea50e0e8037a00924f482ae114534180583f";
    fetchSubmodules = true;
    hash = "sha256-fyZ1dCALyb3wFQ0Cl2VHM6LJAwcxVjmWDJ7GAL5XgtI=";
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
