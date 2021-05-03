{ pkgs, lib, config, ... }:
let
  nixpkgs = import ../nixpkgs/cross-compilation.nix;
in
{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/sd-image.nix"
    ../installation-device.nix
    ../odroidhc4
  ];

  # set cross compiling
  nixpkgs.crossSystem = {
    config = "aarch64-unknown-linux-gnu";
    platform = lib.systems.examples.aarch64-multiplatform.platform // {
      kernelTarget = "Image.gz";
      gcc = {
        arch = "armv8-a";
        extraArgs = [ "-mcrc" "-mcrypto" ];
      };
    };
  };

  # Use pinned packages
  nixpkgs.pkgs = import "${nixpkgs}" {
    inherit (config.nixpkgs) config localSystem crossSystem;
  };
  nixpkgs.overlays = [
    (import ../uboot-bin/overlay.nix)
  ];

  sdImage = {
    compressImage = false;
    # Copy u-boot bootloader to SD card, set partition 1 (unused vfat
    # "FIRMWARE") not bootable and partition 2 (ext4 main) bootable
    postBuildCommands = ''
      dd if="${pkgs.uboot_hardkernel}/u-boot.bin" of="$img" conv=fsync,notrunc bs=512 seek=1
      { echo a; echo 1; echo a; echo 2; echo w; } | fdisk "$img"
    '';
    # Ignore this
    populateFirmwareCommands = "";
    # Fill the root partition with this nix configuration in /etc/nixos
    # and create an initial boot.scr in /boot
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.hardkernel-uboot.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
      mkdir -p ./files/etc/nixos
      cp ${../../configuration.nix} ./files/etc/nixos/configuration.nix
      cp -r ${../.} ./files/etc/nixos/modules
    '';
  };
}
