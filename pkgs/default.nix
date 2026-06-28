{ pkgs, ... }:
{
  apple-font-pingfang = pkgs.callPackage ./apple-font/ttf-pingfang.nix { };
  apple-font-pingfang-relaxed = pkgs.callPackage ./apple-font/ttf-pingfang-relaxed.nix { };
  apple-font-pingfang-ui = pkgs.callPackage ./apple-font/ttf-pingfang-ui.nix { };
  apple-font-pingfang-emoji = pkgs.callPackage ./apple-font/ttf-pingfang-emoji.nix { };
  ccline = pkgs.callPackage ./ccline { };
  ccs = pkgs.callPackage ./scripts/ccs { };
  cli-proxy-api = pkgs.callPackage ./cli-proxy-api { };
  elegant-theme = pkgs.callPackage ./elegant-theme { };
  kulala-core = pkgs.callPackage ./kulala-core { };
  kulala-fmt = pkgs.callPackage ./kulala-fmt { kulala-core = pkgs.callPackage ./kulala-core { }; };
  perry = pkgs.callPackage ./perry { };
  rime-ice = pkgs.callPackage ./rime-ice { };
  screenshot = pkgs.callPackage ./scripts/screenshot { };
  wpsoffice = pkgs.libsForQt5.callPackage ./wpsoffice { };
}
