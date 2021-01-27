{ pkgs, lib, config, ... }:
let
  nixpkgs = import ./nixpkgs.nix;
in
{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/sd-image.nix"
    ./configuration.nix
  ];

  sdImage = {
    compressImage = false;
    firmwareSize = 80;
    postBuildCommands = ''
      dd if="${pkgs.uboot_hardkernel}/u-boot.bin" of="$img" conv=fsync,notrunc bs=512 seek=1
    '';
    populateFirmwareCommands =
      ''
        ${config.boot.loader.hardkernel-uboot.populateCmd} -c ${config.system.build.toplevel} -d ./firmware
      '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      mkdir -p ./files/etc/nixos
      cp ${./configuration.nix} ./files/etc/nixos/configuration.nix
      cp -r ${./modules} ./files/etc/nixos/modules
    '';
  };
  # To speed up installation a little bit, include the complete
  # stdenv in the Nix store on the CD.
  system.extraDependencies = with pkgs;
    [
      stdenv
      stdenvNoCC # for runCommand
      busybox
      jq # for closureInfo
    ];
}
