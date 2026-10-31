{
  lib,
  git,
  makeWrapper,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "ccline";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "Haleclipse";
    repo = "CCometixLine";
    rev = "v${version}";
    hash = "sha256-tzEo+8M86C6EdN31rDVqt8+SCYqeEXRCVFsbtbW41XY=";
  };

  cargoHash = "sha256-dTsuyklpaiYqp5Rq1Q7YUBrmQUH42ve2UY+MwUqF7Ek=";

  nativeBuildInputs = [
    git
    makeWrapper
  ];

  preCheck = ''
    # 上游测试要求源码位于 Git 仓库中，但 fetchFromGitHub 的归档不包含 .git。
    git init --initial-branch=main
  '';

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
