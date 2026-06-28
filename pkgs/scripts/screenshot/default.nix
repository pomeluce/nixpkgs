{
  lib,
  writers,
  libnotify,
  wayshot,
  swappy,
  wl-clipboard,
}:
writers.writeNuBin "screenshot" {
  makeWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        libnotify
        wayshot
        swappy
        wl-clipboard
      ]
    }"
  ];
} (builtins.readFile ./screenshot.nu)

