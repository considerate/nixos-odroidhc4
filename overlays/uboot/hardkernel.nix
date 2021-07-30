{ gcc49Stdenv, git, bc, bison, flex, nettools, buildPackages, arm-gcc49 }:

gcc49Stdenv.mkDerivation {
  name = "hardkernel-uboot";
  src = builtins.fetchTarball {
    url = "https://github.com/hardkernel/u-boot/archive/766167bbe787e494e47376b31cd017b897e9594c.tar.gz";
    sha256 = "0hj49jf9w2w55r7fjpx8asb92r85lws8mvq4mvl1v309z7k56zwv";
  };
  patches = [ ./pwd.diff ./fip_create.diff ];
  nativeBuildInputs = [
    git
    gcc49Stdenv.cc
    bc
    bison
    flex
    nettools
  ];
  depsBuildBuild = [
    arm-gcc49
    buildPackages.gcc49Stdenv.cc
  ];
  makeFlags = [
    "CROSS_COMPILE=${gcc49Stdenv.cc.targetPrefix}"
  ];
  configurePhase = ''
    make odroidc4_defconfig
  '';
  buildPhase = ''
    make
  '';
  installPhase = ''
    mkdir -p $out/fip $out/bin
    cp build/scp_task/bl301.bin \
       build/board/hardkernel/odroidc4/firmware/acs.bin \
       fip/g12a/bl2.bin \
       fip/g12a/bl30.bin \
       fip/g12a/bl31.img \
       fip/g12a/ddr3_1d.fw \
       fip/g12a/ddr4_1d.fw \
       fip/g12a/ddr4_2d.fw \
       fip/g12a/diag_lpddr4.fw \
       fip/g12a/lpddr3_1d.fw \
       fip/g12a/lpddr4_1d.fw \
       fip/g12a/lpddr4_2d.fw \
       fip/g12a/piei.fw \
       fip/g12a/aml_ddr.fw \
       $out/fip/
    cp fip/g12a/aml_encrypt_g12a $out/bin/
  '';
}
