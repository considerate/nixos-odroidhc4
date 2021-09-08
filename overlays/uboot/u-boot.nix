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
  firmwareOdroidC4 = uboot-hardkernel;
  blx_fix = buildPackages.writeShellScript "blx_fix" ''
    case $7 in
      "bl30")
        declare blx_bin_limit=40960
        declare blx01_bin_limit=13312
      ;;
      "bl2")
        declare blx_bin_limit=57344
        declare blx01_bin_limit=4096
      ;;
    esac
    declare -i blx_size=`du -b $1 | awk '{print int($1)}'`
    declare -i zero_size=$blx_bin_limit-$blx_size
    dd if=/dev/zero of=$2 bs=1 count=$zero_size
    cat $1 $2 > $3
    declare -i blx01_size=`du -b $4 | awk '{print int($1)}'`
    declare -i zero_size_01=$blx01_bin_limit-$blx01_size
    dd if=/dev/zero of=$2 bs=1 count=$zero_size_01
    cat $4 $2 > $5
    cat $3 $5 > $6
  '';
  extraConfig = ''
    CONFIG_ZSTD=y
  '';
in
stdenv.mkDerivation {
  name = "uboot";
  src = builtins.fetchTarball {
    url = "https://github.com/u-boot/u-boot/archive/15f7e0dc01d8a851fb1bfbf0e47eab5b67ed26b3.tar.gz";
    sha256 = "1ardkap35pi2dsajag728fnvlvpfmdrsa0igj93wbkbf2ypzzhf6";
  };
  CROSS_COMPILE = stdenv.cc.targetPrefix;
  passAsFile = [ "extraConfig" ];
  configurePhase = ''
    make odroid-c4_defconfig
    cat $extraConfigPath >> .config
  '';
  buildPhase = ''
    make
  '';
  installPhase = ''
    ${blx_fix} ${firmwareOdroidC4}/fip/bl30.bin zero_tmp bl30_zero.bin \
            ${firmwareOdroidC4}/fip/bl301.bin bl301_zero.bin \
            bl30_new.bin bl30
    ${blx_fix} ${firmwareOdroidC4}/fip/bl2.bin zero_tmp bl2_zero.bin \
            ${firmwareOdroidC4}/fip/acs.bin bl21_zero.bin \
            bl2_new.bin bl2
    ${firmwareOdroidC4}/bin/aml_encrypt_g12a --bl30sig --input bl30_new.bin \
      --output bl30_new.bin.g12a.enc --level v3
    ${firmwareOdroidC4}/bin/aml_encrypt_g12a --bl3sig --input bl30_new.bin.g12a.enc \
      --output bl30_new.bin.enc --level v3 --type bl30
    ${firmwareOdroidC4}/bin/aml_encrypt_g12a --bl3sig --input ${firmwareOdroidC4}/fip/bl31.img \
      --output bl31.img.enc --level v3 --type bl31
    ${firmwareOdroidC4}/bin/aml_encrypt_g12a --bl3sig --input u-boot.bin --compress lz4 \
      --output bl33.bin.enc --level v3 --type bl33 --compress lz4
    ${firmwareOdroidC4}/bin/aml_encrypt_g12a --bl2sig --input bl2_new.bin \
      --output bl2.n.bin.sig
    ${firmwareOdroidC4}/bin/aml_encrypt_g12a --bootmk --output u-boot.bin \
      --bl2 bl2.n.bin.sig --bl30 bl30_new.bin.enc --bl31 bl31.img.enc --bl33 bl33.bin.enc \
      --ddrfw1 ${firmwareOdroidC4}/fip/ddr4_1d.fw \
      --ddrfw2 ${firmwareOdroidC4}/fip/ddr4_2d.fw \
      --ddrfw3 ${firmwareOdroidC4}/fip/ddr3_1d.fw \
      --ddrfw4 ${firmwareOdroidC4}/fip/piei.fw \
      --ddrfw5 ${firmwareOdroidC4}/fip/lpddr4_1d.fw \
      --ddrfw6 ${firmwareOdroidC4}/fip/lpddr4_2d.fw \
      --ddrfw7 ${firmwareOdroidC4}/fip/diag_lpddr4.fw \
      --ddrfw8 ${firmwareOdroidC4}/fip/aml_ddr.fw \
      --ddrfw9 ${firmwareOdroidC4}/fip/lpddr3_1d.fw \
      --level v3
    mv u-boot.bin $out
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
