{
  stdenv,
  lib,
  fetchFromGitHub,
  ...
}:

let
  version = "nightly-unstable-2026-07-08";
in
stdenv.mkDerivation {
  pname = "rime-ice";
  inherit version;

  src = fetchFromGitHub {
    owner = "iDvel";
    repo = "rime-ice";
    # version 是展示用的日期字符串, rev 才是实际 commit hash
    # nix-update --version=branch=main 会同时更新两者
    rev = "3a543652a42c21904c62bd881d65e987600f0722";
    fetchSubmodules = true;
    hash = "sha256-lIOTc2zdZH9GXKHuH2lv40I8+KaZxo8nZGbZPyBfXbs=";
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
