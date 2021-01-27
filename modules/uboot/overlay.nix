final: prev: {
  uboot_hardkernel = final.pkgsCross.aarch64-embedded.callPackage ./u-boot.nix {
    filesToInstall = [
      "sd_fuse/sd_fusing.sh"
      "sd_fuse/u-boot.bin"
      "sd_fuse/u-boot.bin.sd.bin"
      "sd_fuse/u-boot.bin.usb.bl2"
      "sd_fuse/u-boot.bin.usb.tpl"
    ];
    extraMeta.platforms = [
      "aarch64-none"
    ];
    crossCompile = true;
  };
  ubootTools_hardkernel = final.callPackage ./u-boot.nix {
    extraMakeFlags = [
      "HOST_TOOLS_ALL=y"
      "CROSS_BUILD_TOOLS=1"
      "NO_SDL=1"
      "tools"
    ];
    filesToInstall = [
      "build/tools/dumpimage"
      "build/tools/mkenvimage"
      "build/tools/mkimage"
      # build/tools/fdtgrep
      # build/tools/kwboot
    ];
    installDir = "$out/bin";
    crossCompile = false;
    extraMeta.platforms = final.lib.platforms.linux;
  };
}
