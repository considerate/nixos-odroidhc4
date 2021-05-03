{ pkgs }:

pkgs.substituteAll {
  src = ./boot-ini-builder.sh;
  isExecutable = true;
  # ubootTools is just for mkimage. the one in nixpkgs is enough, we don't have
  # to build our own.
  path = [ pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.ubootTools pkgs.gzip ];
  inherit (pkgs) bash;
}
