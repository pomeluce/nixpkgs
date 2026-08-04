{
  stdenv,
  lib,
  fetchFromGitHub,
  ...
}:

let
  version = "nightly-unstable-2026-08-02";
in
stdenv.mkDerivation {
  pname = "rime-ice";
  inherit version;

  src = fetchFromGitHub {
    owner = "iDvel";
    repo = "rime-ice";
    # version 是展示用的日期字符串, rev 才是实际 commit hash
    # nix-update --version=branch=main 会同时更新两者
    rev = "569ff3bc65dd4aec0a26b33c49c8bbdfa8b5fd57";
    fetchSubmodules = true;
    hash = "sha256-U1aof8zSRKMXPDNXIB+LxbeRz5lBTegEG37iaFXS6fY=";
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
