{ writers }: writers.writeNuBin "ccs" { makeWrapperArgs = [ ]; } (builtins.readFile ./ccs.nu)

