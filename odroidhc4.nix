# nix-build '<nixpkgs/nixos>' -I nixos-config=odroidhc4 -A config.system.build.sdImage
{ pkgs, config, lib, ... }:
let
  linux_hardkernel = pkgs.callPackage ./kernel.nix {
    kernelPatches = [
      ({ name = "wip"; patch = ./wip.diff; })
    ];
  };
  uboot = pkgs.callPackage ./uboot.nix { };
in
with lib;
{
  # pick the right kernel
  boot.kernelPackages = pkgs.linuxPackagesFor linux_hardkernel;

  # set cross compiling
  nixpkgs.crossSystem = {
    config = "aarch64-unknown-linux-gnu";
    platform = (((import <stable/lib>).systems.examples.aarch64-multiplatform.platform) // {
      gcc = {
        arch = "armv8-a+crc+crypto";
      };
    });
  };

  #
  # Bootloader (UBoot, extlinux)
  #
  boot.loader.generic-extlinux-compatible = {
    enable = true;
  };
  # sdImage.populateBootCommands = with config.system.build; ''
  #   ${installBootLoaderNative} ${toplevel} -d boot
  # '';
  # sdImage.postBuildCommands =
  #   ''
  #     dd if=${uboot}/u-boot.bin of=$img conv=notrunc bs=512 seek=1
  #   '';

  sdImage = {
    populateFirmwareCommands =
      let
        boot-ini = pkgs.writeText "boot.ini" ''
        '';
      in
      ''
        cp ${boot-ini} firmware/boot.ini
        cp ${linux_hardkernel.kernel}/Image.gz ${linux_hardkernel.kernel}/dts/amlogic/meson64_odroidhc4.dtb firmware/
      '';
  };

  # networking
  # networking.nameservers = [ "1.1.1.1" "8.8.8.8" "8.8.4.4" ];

  # SSH
  services.openssh.enable = mkDefault true;
  services.openssh.permitRootLogin = mkDefault "yes";

  # DNS
  services.resolved.enable = true;
  services.resolved.dnssec = "false";

  # set a default root password
  users.users.root.initialPassword = lib.mkDefault "toor";
}
