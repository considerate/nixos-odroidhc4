final: prev: {
  uboot_hardkernel = final.callPackage ./u-boot-odroid.nix {
    inherit (final.callPackage ./hardkernel-firmware.nix { }) firmwareOdroidC4;
  };
  ubootTools_hardkernel = final.buildPackages.callPackage ./uboot-tools.nix { };
  buildPackages = prev.buildPackages // {
    ubootTools_hardkernel = final.buildPackages.buildPackages.callPackage ./uboot-tools.nix { };
  };
}
