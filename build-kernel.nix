{ pkgs ? import <stable>
, arm ? import <stable> {
    crossSystem =
      {
        config = "aarch64-unknown-linux-gnu";
        platform = (((import <stable/lib>).systems.examples.aarch64-multiplatform.platform) // {
          gcc = {
            arch = "armv8-a+crc+crypto";
          };
          kernelTarget = "Image.gz";
        });
      };
    config = {
      allowBroken = true;
      allowUnfree = true;
    };
  }
}:
let
  linux_hardkernel = arm.callPackage
    ./kernel.nix
    {
      kernelPatches = [
        # arm.kernelPatches.bridge_stp_helper
        # arm.kernelPatches.request_key_helper
        # arm.kernelPatches.modinst_arg_list_too_long
        # ({ name = "pointer-types-warning"; patch = ./pointer.diff; })
        ({ name = "wip"; patch = ./wip.diff; })
      ];
    };
  #linuxPackages_hardkernel = arm.recurseIntoAttrs (arm.linuxPackagesFor linux_hardkernel);
  linuxPackages_hardkernel = arm.linuxPackagesFor linux_hardkernel;
in
# arm.hello
  # linux_hardkernel
linuxPackages_hardkernel.kernel
