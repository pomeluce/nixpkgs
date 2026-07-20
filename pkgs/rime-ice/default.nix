{
  stdenv,
  lib,
  fetchFromGitHub,
  ...
}:

let
  version = "nightly-unstable-2026-07-19";
in
stdenv.mkDerivation {
  pname = "rime-ice";
  inherit version;

  src = fetchFromGitHub {
    owner = "iDvel";
    repo = "rime-ice";
    # version 是展示用的日期字符串, rev 才是实际 commit hash
    # nix-update --version=branch=main 会同时更新两者
    rev = "b681a34f788795034b3b288830f4861980bc8b0d";
    fetchSubmodules = true;
    hash = "sha256-kqn3c5qAotPmItFQURrGtWIko4vQPNqH7S3d1t4nwwU=";
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
