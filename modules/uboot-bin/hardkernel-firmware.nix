# https://github.com/NixOS/nixpkgs/pull/101454
{ stdenv
, lib
, fetchgit
, buildPackages
, pkgsCross
}:
let
  buildHardkernelFirmware =
    { version ? null
    , src ? null
    , name ? ""
    , filesToInstall
    , installDir ? "$out"
    , defconfig
    , extraMeta ? { }
    , ...
    } @ args: stdenv.mkDerivation ({
      pname = "uboot-hardkernel-firmware-${name}";

      nativeBuildInputs = [
        buildPackages.git
        buildPackages.hostname
        pkgsCross.arm-embedded.stdenv.cc
      ];

      depsBuildBuild = [
        buildPackages.gcc49
      ] ++ lib.optional (stdenv.buildPlatform != stdenv.hostPlatform) buildPackages.stdenv.cc
      ++ lib.optional (!stdenv.isAarch64) pkgsCross.aarch64-multiplatform.buildPackages.gcc49;

      postPatch = ''
        substituteInPlace Makefile --replace "/bin/pwd" "pwd"
      '';

      makeFlags = [
        "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
        "CROSS_COMPILE_32=${pkgsCross.arm-embedded.stdenv.cc.targetPrefix}"
        "${defconfig}"
        "bl301.bin"
      ]
      ++ lib.optional (!stdenv.isAarch64) "CROSS_COMPILE=${pkgsCross.aarch64-multiplatform.stdenv.cc.targetPrefix}";

      installPhase = ''
        mkdir -p ${installDir}
        cp ${lib.concatStringsSep " " filesToInstall} ${installDir}
      '';

      meta = with lib; {
        homepage = "https://www.hardkernel.com/";
        description = "Das U-Boot from Hardkernel with Odroid embedded devices firmware and support";
        license = licenses.unfreeRedistributableFirmware;
        maintainers = with maintainers; [ considerate aarapov ];
      } // extraMeta;
    } // removeAttrs args [ "extraMeta" ]);
in
{
  inherit buildHardkernelFirmware;

  # https://wiki.odroid.com/odroid-c4/software/building_u-boot
  firmwareOdroidC4 = buildHardkernelFirmware {
    name = "firmware-odroid-c4";
    defconfig = "odroidc4_defconfig";
    version = "2015.01";
    src = fetchgit {
      url = "https://github.com/hardkernel/u-boot.git";
      rev = "90ebb7015c1bfbbf120b2b94273977f558a5da46"; # "odroidg12-v2015.01"
      sha256 = "06d9zk2a9q9mhnjlgi3p8rw1ymy37344wws6lxaa6b5x7v1s48yv";
      leaveDotGit = true;
    };

    prePatch = ''
      substituteInPlace ./arch/arm/cpu/armv8/g12a/firmware/scp_task/Makefile \
        --replace "CROSS_COMPILE" "CROSS_COMPILE_32"
    '';

    filesToInstall = [
      "build/board/hardkernel/odroidc4/firmware/acs.bin"
      "build/scp_task/bl301.bin"
      "fip/g12a/bl2.bin"
      "fip/g12a/bl30.bin"
      "fip/g12a/bl31.img"
      "fip/g12a/ddr3_1d.fw"
      "fip/g12a/ddr4_1d.fw"
      "fip/g12a/ddr4_2d.fw"
      "fip/g12a/lpddr3_1d.fw"
      "fip/g12a/lpddr4_1d.fw"
      "fip/g12a/lpddr4_2d.fw"
      "fip/g12a/diag_lpddr4.fw"
      "fip/g12a/piei.fw"
      "fip/g12a/aml_ddr.fw"
      "fip/g12a/aml_encrypt_g12a"
      "sd_fuse/sd_fusing.sh"
    ];

    extraMeta.platforms = [ "aarch64-linux" ];
  };
}
