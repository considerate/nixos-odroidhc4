{ stdenvNoCC
, gzip
, ubootTools
, initrdPath
}:
stdenvNoCC.mkDerivation {
  name = "initrd-uboot";
  buildCommand = ''
    ${gzip}/bin/gzip -d < "${initrdPath}" > tmp
    ${ubootTools}/bin/mkimage -A arm64 -O linux -T ramdisk -C none -d tmp $out
  '';
}
