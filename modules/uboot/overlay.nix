final: prev:
let
  platform = final.lib.systems.examples.aarch64-multiplatform // {
    gcc = {
      arch = "armv8-a+crypto";
    };
  };
  arm64 = final.pkgsCross.aarch64-embedded;
  arm = final.pkgsCross.arm-embedded;
  uboot-hardkernel = arm64.callPackage ./hardkernel.nix {
    arm-gcc49 = arm.buildPackages.gcc49;
  };
  with-crypto = import final.path {
    crossSystem = platform;
  };
  meson64-tools = with-crypto.callPackage ./meson64-tools.nix { };
  blx_fix = arm64.buildPackages.callPackage ./blx_fix.nix { };
  uboot = arm64.callPackage ./u-boot.nix {
    inherit uboot-hardkernel meson64-tools blx_fix;
  };
in
{
  uboot-hardkernel = uboot;
  ubootTools-hardkernel = final.buildPackages.ubootTools;
  buildPackages = prev.buildPackages // {
    ubootTools-hardkernel = final.buildPackages.buildPackages.ubootTools;
  };
}
