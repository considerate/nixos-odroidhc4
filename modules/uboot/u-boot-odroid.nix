# https://u-boot.readthedocs.io/en/latest/board/amlogic/odroid-c4.html
{ buildUBoot
, stdenv
, pkgsCross
, buildPackages
, firmwareOdroidC4
, lib
, fetchurl
}:
assert
lib.assertMsg (!stdenv.buildPlatform.isAarch64)
  ''
    U-Boot for Odroid (H)C4 must be cross-compiled on an x86_64-linux system.

    Once built, U-Boot firmware images must be signed by the 'aml_encrypt_g12a'
    tool. This tool is available for x86_64-linux platform only and Amlogic
    hasn't released the source code.
  '';
let
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
in
buildUBoot {
  defconfig = "odroid-c4_defconfig";
  version = "2021.01";
  src = fetchurl {
    url = "ftp://ftp.denx.de/pub/u-boot/u-boot-2021.01.tar.bz2";
    sha256 = "0m04glv9kn3bhs62sn675w60wkrl4m3a4hnbnnw67s3l198y21xl";
  };

  postBuild = ''
    ${blx_fix} ${firmwareOdroidC4}/bl30.bin zero_tmp bl30_zero.bin \
            ${firmwareOdroidC4}/bl301.bin bl301_zero.bin \
            bl30_new.bin bl30
    ${blx_fix} ${firmwareOdroidC4}/bl2.bin zero_tmp bl2_zero.bin \
            ${firmwareOdroidC4}/acs.bin bl21_zero.bin \
            bl2_new.bin bl2
    ${firmwareOdroidC4}/aml_encrypt_g12a --bl30sig --input bl30_new.bin \
      --output bl30_new.bin.g12a.enc --level v3
    ${firmwareOdroidC4}/aml_encrypt_g12a --bl3sig --input bl30_new.bin.g12a.enc \
      --output bl30_new.bin.enc --level v3 --type bl30
    ${firmwareOdroidC4}/aml_encrypt_g12a --bl3sig --input ${firmwareOdroidC4}/bl31.img \
      --output bl31.img.enc --level v3 --type bl31
    ${firmwareOdroidC4}/aml_encrypt_g12a --bl3sig --input u-boot.bin --compress lz4 \
      --output bl33.bin.enc --level v3 --type bl33 --compress lz4
    ${firmwareOdroidC4}/aml_encrypt_g12a --bl2sig --input bl2_new.bin \
      --output bl2.n.bin.sig
    ${firmwareOdroidC4}/aml_encrypt_g12a --bootmk --output u-boot.bin \
      --bl2 bl2.n.bin.sig --bl30 bl30_new.bin.enc --bl31 bl31.img.enc --bl33 bl33.bin.enc \
      --ddrfw1 ${firmwareOdroidC4}/ddr4_1d.fw \
      --ddrfw2 ${firmwareOdroidC4}/ddr4_2d.fw \
      --ddrfw3 ${firmwareOdroidC4}/ddr3_1d.fw \
      --ddrfw4 ${firmwareOdroidC4}/piei.fw \
      --ddrfw5 ${firmwareOdroidC4}/lpddr4_1d.fw \
      --ddrfw6 ${firmwareOdroidC4}/lpddr4_2d.fw \
      --ddrfw7 ${firmwareOdroidC4}/diag_lpddr4.fw \
      --ddrfw8 ${firmwareOdroidC4}/aml_ddr.fw \
      --ddrfw9 ${firmwareOdroidC4}/lpddr3_1d.fw \
      --level v3
  '';

  filesToInstall = [ "u-boot.bin" "${firmwareOdroidC4}/sd_fusing.sh" ];
  extraMeta.platforms = [ "aarch64-linux" ];
}
