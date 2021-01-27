# nix-build '<nixpkgs/nixos>' -I nixos-config=odroidhc4 -A config.system.build.sdImage
{ pkgs, config, lib, ... }:
let
  nixpkgs = import ./nixpkgs.nix;
in
with lib;
{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/sd-image.nix"
    ./modules/base.nix
    ./modules/installation-device.nix
    ./modules/hardkernel-uboot.nix
  ];
  # pick the right kernel
  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_hardkernel;

  boot.initrd.availableKernelModules = [
    # Allows early (earlier) modesetting for the Raspberry Pi
    "vc4"
    "bcm2835_dma"
    "i2c_bcm2835"
    # Allows early (earlier) modesetting for Allwinner SoCs
    "sun4i_drm"
    "sun8i_drm_hdmi"
    "sun8i_mixer"
  ];

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

  nixpkgs.overlays = [
    (final: prev: {
      linux_hardkernel = final.callPackage ./kernel.nix {
        kernelPatches = [
          ({ name = "wip"; patch = ./wip.diff; })
        ];
      };
      uboot_hardkernel = final.pkgsCross.aarch64-embedded.callPackage ./u-boot.nix {
        filesToInstall = [
          "sd_fuse/sd_fusing.sh"
          "sd_fuse/u-boot.bin"
          "sd_fuse/u-boot.bin.sd.bin"
          "sd_fuse/u-boot.bin.usb.bl2"
          "sd_fuse/u-boot.bin.usb.tpl"
        ];
        extraMeta.platforms = [
          "aarch64-none"
        ];
        crossCompile = true;
      };
      ubootTools_hardkernel = final.callPackage ./u-boot.nix {
        extraMakeFlags = [
          "HOST_TOOLS_ALL=y"
          "CROSS_BUILD_TOOLS=1"
          "NO_SDL=1"
          "tools"
        ];
        filesToInstall = [
          "build/tools/dumpimage"
          "build/tools/mkenvimage"
          "build/tools/mkimage"
          # build/tools/fdtgrep
          # build/tools/kwboot
        ];
        installDir = "$out/bin";
        crossCompile = false;
        extraMeta.platforms = lib.platforms.linux;
      };
    })
  ];

  #
  # Bootloader (UBoot, hardkernel)
  #
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = false;
  boot.loader.hardkernel-uboot.enable = true;

  # To speed up installation a little bit, include the complete
  # stdenv in the Nix store on the CD.
  system.extraDependencies = with pkgs;
    [
      stdenv
      stdenvNoCC # for runCommand
      busybox
      jq # for closureInfo
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
    '';
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDiRIiaJvpr2JtisMaTN7QhYENBUQ9r/WzthEuMcAXNetCHbP5Ug74j3YA4DcI3ajhenqc3BGQPP0lh2AHZ0uriFqkxMCezSfu0+gSygzUUZh2lJfEnnPuv9J6BKWEtu1cr/pZQpfyye5RfgjuYe+v3aY14InDT0LW/UMR32EPK9yhuG0s+gkMRuqfF8HCUEgA6xDzg67CY9KfCu2JuekCHJJzdTSERkEkejUCd3cnlV63eUdo+SDrFdfsOR5CIpKPq27TpRAvqTvjuILLlG8mc1O/EUdf8P13Y3SF1itiTGBMCnmN/X9hZfzKL4x8skhqWg6sD2p+O8lbmfdI1FV0Gc6RZvHXJHJjXHIVAu1OSqduOMlPVNPfxTfXQh6VTexPAiPR77EJt2X2b6bL4HvgZxTNPh0cZTbpPcbDRmk8AuHfV6cDWNFjMIDytLeleL68g1cedWM1wNnJh4sy76CvY61QKvoNpcl+d8xwDDDDSPPhSGE8MXwEXgqsnrZTqoKc= considerate@considerate-nixos"
  ];

  # SSH
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # DNS
  services.resolved.enable = true;
  services.resolved.dnssec = "false";

  # set a default root password
  users.users.root.initialPassword = "toor";

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "fat32";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };
}
