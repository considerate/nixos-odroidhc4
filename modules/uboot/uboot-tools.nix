{ buildUBoot, fetchurl, lib }:
buildUBoot {
  version = "2021.10";
  src = builtins.fetchTarball {
    url = "https://github.com/u-boot/u-boot/archive/15f7e0dc01d8a851fb1bfbf0e47eab5b67ed26b3.tar.gz";
    sha256 = "1ardkap35pi2dsajag728fnvlvpfmdrsa0igj93wbkbf2ypzzhf6";
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
