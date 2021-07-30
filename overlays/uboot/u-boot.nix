{ stdenv
, git
, bc
, bison
, flex
, nettools
, openssl
, buildPackages
, uboot-hardkernel
, meson64-tools
, blx_fix
}:
let
in
stdenv.mkDerivation {
  name = "uboot";
  src = builtins.fetchTarball {
    url = "https://github.com/u-boot/u-boot/archive/15f7e0dc01d8a851fb1bfbf0e47eab5b67ed26b3.tar.gz";
    sha256 = "1ardkap35pi2dsajag728fnvlvpfmdrsa0igj93wbkbf2ypzzhf6";
  };
  CROSS_COMPILE = stdenv.cc.targetPrefix;
  configurePhase = ''
    make odroid-c4_defconfig
  '';
  buildPhase = ''
    make
  '';
  installPhase = ''
    mkdir fip
    cp ${uboot-hardkernel}/fip/* fip/
    cp u-boot.bin fip/bl33.bin
    ${blx_fix} \
      fip/bl30.bin \
      fip/zero_tmp \
      fip/bl30_zero.bin \
      fip/bl301.bin \
      fip/bl301_zero.bin \
      fip/bl30_new.bin \
      bl30

    ${blx_fix} \
      fip/bl2.bin \
      fip/zero_tmp \
      fip/bl2_zero.bin \
      fip/acs.bin \
      fip/bl21_zero.bin \
      fip/bl2_new.bin \
      bl2

    ${meson64-tools}/bin/bl30sig \
      --input fip/bl30_new.bin \
      --output fip/bl30_new.bin.g12a.enc \
      --level v3
    ${meson64-tools}/bin/bl3sig \
      --input fip/bl30_new.bin.g12a.enc \
      --output fip/bl30_new.bin.enc \
      --level v3 --type bl30
    ${meson64-tools}/bin/bl3sig \
      --input fip/bl31.img \
      --output fip/bl31.img.enc \
      --level v3 --type bl31
    ${meson64-tools}/bin/bl3sig \
      --input fip/bl33.bin --compress lz4 \
      --output fip/bl33.bin.enc \
      --level v3 --type bl33 --compress lz4
    ${meson64-tools}/bin/bl2sig \
      --input fip/bl2_new.bin \
      --output fip/bl2.n.bin.sig
    ${meson64-tools}/bin/bootmk \
      --output $out \
      --bl2 fip/bl2.n.bin.sig \
      --bl30 fip/bl30_new.bin.enc \
      --bl31 fip/bl31.img.enc \
      --bl33 fip/bl33.bin.enc \
      --ddrfw1 fip/ddr4_1d.fw \
      --ddrfw2 fip/ddr4_2d.fw \
      --ddrfw3 fip/ddr3_1d.fw \
      --ddrfw4 fip/piei.fw \
      --ddrfw5 fip/lpddr4_1d.fw \
      --ddrfw6 fip/lpddr4_2d.fw \
      --ddrfw7 fip/diag_lpddr4.fw \
      --ddrfw8 fip/aml_ddr.fw \
      --ddrfw9 fip/lpddr3_1d.fw \
      --level v3
  '';
  nativeBuildInputs = [
    git
    bc
    bison
    flex
    nettools
  ];

  depsBuildBuild = [
    buildPackages.stdenv.cc
    buildPackages.openssl.dev
  ];
}
