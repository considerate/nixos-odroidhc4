{ pkgs }:

pkgs.substituteAll {
  src = ./boot-ini-builder.sh;
  isExecutable = true;
  path = [ pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.ubootTools_hardkernel pkgs.gzip ];
  configIni = ./config.ini;
  inherit (pkgs) bash;
}
