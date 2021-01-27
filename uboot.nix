{ pkgs ? import <stable> { }
, arm64 ? pkgs.pkgsCross.aarch64-embedded
, arm ? pkgs.pkgsCross.arm-embedded
, defconfig ? "odroidc4_defconfig"
, installDir ? "$out"
, lib
, filesToInstall
}:
arm64.gcc49Stdenv.mkDerivation {
  name = "uboot";
  src = builtins.fetchGit {
    url = "https://github.com/hardkernel/u-boot.git";
    ref = "odroidg12-v2015.01";
    rev = "90ebb7015c1bfbbf120b2b94273977f558a5da46";
  };
  patches = [
    ./uboot.diff
  ];
  makeFlags = [
    "DTC=dtc"
    "CROSS_COMPILE=${arm64.gcc49Stdenv.cc.targetPrefix}"
  ];
  configurePhase = ''
    rm fip/fip_create
    export ARCH=arm64
    make ${defconfig}
  '';
  buildPhase = "make -j8";
  installPhase = ''
    mkdir ${installDir}
    cp ${lib.concatStringsSep " " filesToInstall} ${installDir}
  '';
  depsBuildBuild = [
    arm.buildPackages.gcc49
    pkgs.buildPackages.stdenv.cc
  ];
  nativeBuildInputs = with pkgs; [
    bc
    bison
    flex
    nettools
    openssl
  ];
  # make[2]: *** No rule to make target 'lib/efi_loader/helloworld.efi', needed by '__build'.  Stop.
  enableParallelBuilding = false;

  dontStrip = true;
}
