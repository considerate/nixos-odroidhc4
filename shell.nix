{ pkgs ? import <stable> { }
, arm64 ? import <stable> {
    crossSystem = pkgs.lib.systems.examples.aarch64-embedded;
  }
, arm ? import <stable> {
    crossSystem = pkgs.lib.systems.examples.arm-embedded;
  }
}:
arm64.stdenv.mkDerivation {
  name = "testing";
  depsBuildBuild = [ arm.buildPackages.gcc ];
}
