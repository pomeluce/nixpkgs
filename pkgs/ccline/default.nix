{
  lib,
  git,
  makeWrapper,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "ccline";
  version = "1.1.2";

  src = fetchFromGitHub {
    owner = "Haleclipse";
    repo = "CCometixLine";
    rev = "v${version}";
    hash = "sha256-W6+eGp8S6weOlS5WpmMR9JT4BVtyhettmtaFTStmyQk=";
  };

  cargoHash = "sha256-ejSDR43RUebxuHiRG3MsppDhgDpH44o+L+jfOZf0x5A=";

  nativeBuildInputs = [
    makeWrapper
  ];

  postInstall = ''
    ln -s $out/bin/ccometixline $out/bin/ccline
  '';

  postFixup = ''
    # ccline 会读取 git 分支/状态, 这里把 git 放进运行时 PATH
    wrapProgram $out/bin/ccometixline \
      --prefix PATH : ${lib.makeBinPath [ git ]}
  '';

  meta = {
    description = "High-performance Claude Code statusline tool written in Rust";
    homepage = "https://github.com/Haleclipse/CCometixLine";
    changelog = "https://github.com/Haleclipse/CCometixLine/releases";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    mainProgram = "ccline";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
