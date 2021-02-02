{ buildUBoot, fetchurl, lib }:
buildUBoot {
  version = "2021.01";
  src = fetchurl {
    url = "ftp://ftp.denx.de/pub/u-boot/u-boot-2021.01.tar.bz2";
    sha256 = "0m04glv9kn3bhs62sn675w60wkrl4m3a4hnbnnw67s3l198y21xl";
  };
  defconfig = "tools-only_defconfig";
  installDir = "$out/bin";
  hardeningDisable = [ ];
  dontStrip = false;
  extraMeta.platforms = lib.platforms.linux;
  extraMakeFlags = [ "HOST_TOOLS_ALL=y" "CROSS_BUILD_TOOLS=1" "NO_SDL=1" "tools" ];
  filesToInstall = [
    "tools/dumpimage"
    "tools/fdtgrep"
    "tools/kwboot"
    "tools/mkenvimage"
    "tools/mkimage"
  ];
}
