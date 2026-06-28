{
  lib,
  go_1_26,
  buildGoModule,
  fetchFromGitHub,
  ...
}:

let
  version = "7.2.42";
  hash = "sha256-ZaUCRIgKo3NQCXI9tMOwB70zl94n8smOwUXlc1w7EzQ=";
  vendorHash = "sha256-vQU3hLDga5PMUwH4KSB3T5sZ1uPUgHQHeyQGJTKHIYs=";
in
buildGoModule.override { go = go_1_26; } {
  pname = "cli-proxy-api";
  inherit version vendorHash;

  src = fetchFromGitHub {
    owner = "router-for-me";
    repo = "CLIProxyAPI";
    rev = "v${version}";
    inherit hash;
  };

  subPackages = [ "cmd/server" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${version}"
    "-X main.Commit=nixpkgs"
    "-X main.BuildDate=1970-01-01T00:00:00Z"
  ];

  postPatch = ''
    if [[ -f go.mod ]]; then
      goVersion=$(go env GOVERSION | sed 's/^go//')
      echo "unpinGoModVersion: setting go.mod go directive to $goVersion"
      sed -i "s/^go .*/go $goVersion/" go.mod
      if grep -q '^toolchain ' go.mod; then
        echo "unpinGoModVersion: removing toolchain directive from go.mod"
        sed -i '/^toolchain /d' go.mod
      fi
    fi
  '';

  preInstall = ''
    if [[ ! -v HOME ]] || [[ ! -w $HOME ]]; then
      HOME="$NIX_BUILD_TOP/.version-check-home"
      mkdir -p "$HOME"
      export HOME
    fi
  '';

  postInstall = ''
    mv $out/bin/server $out/bin/cli-proxy-api
  '';

  doInstallCheck = false;

  passthru.category = "AI Coding Agents";

  meta = with lib; {
    description = "Unified proxy providing OpenAI/Gemini/Claude/Codex compatible APIs for AI coding CLI tools";
    homepage = "https://github.com/router-for-me/CLIProxyAPI";
    changelog = "https://github.com/router-for-me/CLIProxyAPI/releases";
    license = licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    mainProgram = "cli-proxy-api";
    platforms = platforms.all;
  };
}
