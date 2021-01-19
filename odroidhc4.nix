# nix-build '<nixpkgs/nixos>' -I nixos-config=odroidhc4 -A config.system.build.sdImage
{ pkgs, config, lib, ... }:
let
  linux_hardkernel = pkgs.callPackage ./kernel.nix {
    kernelPatches = [
      ({ name = "wip"; patch = ./wip.diff; })
    ];
  };
  uboot = pkgs.callPackage ./uboot.nix { };
  nixpkgs = import ./nixpkgs.nix;
in
with lib;
{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/sd-image.nix"
    ./base.nix
    ./installation-device.nix
  ];
  # pick the right kernel
  boot.kernelPackages = pkgs.linuxPackagesFor linux_hardkernel;

  # set cross compiling
  nixpkgs.crossSystem = {
    config = "aarch64-unknown-linux-gnu";
    platform = (((import "${nixpkgs}/lib").systems.examples.aarch64-multiplatform.platform) // {
      kernelTarget = "Image.gz";
      gcc = {
        arch = "armv8-a";
        extraArgs = [ "-mcrc" "-mcrypto" ];
      };
    });
  };

  #
  # Bootloader (UBoot, extlinux)
  #
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible = {
    enable = true;
  };

  sdImage = {
    firmwareSize = 40;
    populateFirmwareCommands =
      ''
        cp ${./boot.ini} firmware/boot.ini
        cp ${./config.ini} firmware/config.ini
        cp ${linux_hardkernel}/Image.gz ${linux_hardkernel}/dtbs/amlogic/meson64_odroidhc4.dtb firmware/
      '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
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
