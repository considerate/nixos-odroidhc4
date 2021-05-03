final: prev: {
  uboot_hardkernel = final.callPackage ./u-boot-odroid.nix {
    inherit (final.callPackage ./hardkernel-firmware.nix { }) firmwareOdroidC4;
  };
}
