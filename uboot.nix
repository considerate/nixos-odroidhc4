{ pkgs ? import <stable> { }
, arm64 ? import <stable> {
    crossSystem = pkgs.lib.systems.examples.aarch64-embedded;
  }
, arm ? import <stable> {
    crossSystem = pkgs.lib.systems.examples.arm-embedded;
  }
}:
arm64.gcc49Stdenv.mkDerivation {
  name = "testing";
  src = builtins.fetchGit {
    url = "https://github.com/hardkernel/u-boot.git";
    ref = "odroidg12-v2015.01";
    rev = "90ebb7015c1bfbbf120b2b94273977f558a5da46";
  };
  patches = [
    ./uboot.diff
  ];
  # KBUILD_OUTPUT = "$out";
  configurePhase = ''
    rm fip/fip_create
    export ARCH=arm64
    export CROSS_COMPILE=aarch64-none-elf-
    make odroidc4_defconfig
    pwd
  '';
  buildPhase = "make -j8";
  installPhase = ''
    mkdir $out
    cp -r sd_fuse $out/
  '';
  depsBuildBuild = [ arm.buildPackages.gcc49 ];
  nativeBuildInputs = [ pkgs.gnumake pkgs.gcc pkgs.dtc pkgs.git pkgs.nettools pkgs.bc pkgs.which ];

}
