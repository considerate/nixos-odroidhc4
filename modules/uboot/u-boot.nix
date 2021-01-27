{ defconfig ? "odroidc4_defconfig"
, installDir ? "$out"
, lib
, filesToInstall
, gcc49Stdenv
, gcc49
, git
, bc
, bison
, flex
, nettools
, openssl
, stdenv
, buildPackages
, pkgsCross
, extraMakeFlags ? [ ]
, extraMeta ? { }
, crossCompile ? true
, ...
}@args:
let
  arm = pkgsCross.arm-embedded;
  arm64 = pkgsCross.aarch64-embedded;
  defaultArgs = rec {
    pname = "uboot";
    version = "odroidg12-v2015.01";
    src = buildPackages.fetchFromGitHub {
      owner = "hardkernel";
      repo = "u-boot";
      rev = "90ebb7015c1bfbbf120b2b94273977f558a5da46";
      sha256 = "0kv9hpsgpbikp370wknbyj6r6cyhp7hng3ng6xzzqaw13yy4qiz9";
    };
    patches = [
      ./uboot.diff
    ];
    makeFlags = [
      "DTC=dtc"
    ]
    ++ lib.optional (!crossCompile) "CROSS_COMPILE=${gcc49Stdenv.cc.targetPrefix}"
    ++ extraMakeFlags;
    # CROSS_COMPILE can't be specfied as a make flag because we need arm-none-eabi-
    # to be used for the boot loader firmware, and specifying it in `makeFlags` overrides
    # the setting of CROSS_COMPILE to "arm-none-eabi-".
    configurePhase = lib.optionalString crossCompile
      ''
        export "CROSS_COMPILE=${gcc49Stdenv.cc.targetPrefix}"
      '' + ''
      rm fip/fip_create
      export ARCH=arm
      echo $CROSS_COMPILE
      make ${defconfig}
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p ${installDir}
      cp ${lib.concatStringsSep " " filesToInstall} ${installDir}
      runHook postInstall
    '';
    depsBuildBuild = [
      arm.buildPackages.gcc49
      buildPackages.gcc49Stdenv.cc
    ];
    nativeBuildInputs = [
      git
      bc
      bison
      flex
      nettools
      openssl
    ];
    # make[2]: *** No rule to make target 'lib/efi_loader/helloworld.efi', needed by '__build'.  Stop.
    enableParallelBuilding = false;

    dontStrip = true;
    meta = with lib; {
      homepage = "http://www.denx.de/wiki/U-Boot/";
      description = "Boot loader for embedded systems";
      license = licenses.gpl2;
      maintainers = with maintainers; [ dezgeg samueldr lopsided98 ];
    } // extraMeta;
  };
  finalArgs = defaultArgs //
    (builtins.removeAttrs
      args
      [
        "lib"
        "filesToInstall"
        "gcc49Stdenv"
        "gcc49"
        "git"
        "bc"
        "bison"
        "flex"
        "nettools"
        "openssl"
        "stdenv"
        "buildPackages"
        "pkgsCross"
        "extraMakeFlags"
        "extraMeta"
        "crossCompile"
      ]
    );
in
gcc49Stdenv.mkDerivation finalArgs
