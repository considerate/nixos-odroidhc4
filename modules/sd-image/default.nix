{ pkgs, lib, config, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
    # should we include this module or should we treat the SD
    # card as the final system to run?
    "${modulesPath}/profiles/installation-device.nix"
    ../odroidhc4
  ];

  security.polkit.enable = false;

  nixpkgs.overlays = [
    (final: prev: {
      smartmontools = prev.smartmontools.override { enableMail = false; };
    })
  ];

  # Remove zfs from supported filesystems as it fails when cross-compiling due
  # to not being able to build kernel module
  boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];

  sdImage = {
    compressImage = false;
    # Use 512 MB for boot partition to fit multiple kernel versions
    firmwareSize = 512;
    # Copy u-boot bootloader to SD card
    postBuildCommands = ''
      dd if="${pkgs.uboot-hardkernel}" of="$img" conv=fsync,notrunc bs=512 skip=1 seek=1
      dd if="${pkgs.uboot-hardkernel}" of="$img" conv=fsync,notrunc bs=1 count=444
    '';
    # Fill the FIRMWARE partition with the u-boot files, linux kernel and initrd (ramdisk)
    populateFirmwareCommands = ''
      ${config.boot.loader.hardkernel-uboot.populateCmd} -c ${config.system.build.toplevel} -d ./firmware
    '';
    # Fill the root partition with this nix configuration in /etc/nixos
    # and create a mount point for the FIRMWARE partition at /boot
    populateRootCommands = ''
      mkdir -p ./files/boot ./files/etc/nixos
      cp -r --target-directory=./files/etc/nixos ${lib.cleanSource ../..}/*
      chmod -R u+w ./files/etc/nixos
    '';
  };
}
