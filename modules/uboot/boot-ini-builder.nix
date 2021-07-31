{ pkgs }:

pkgs.substituteAll {
  src = ./boot-ini-builder.sh;
  isExecutable = true;
  path = [
    pkgs.coreutils
    pkgs.gnused
    pkgs.gnugrep
    pkgs.gzip
    pkgs.ubootTools-hardkernel
    pkgs.zstd
  ];
  configIni = ./config.ini;
  inherit (pkgs) bash;
}
