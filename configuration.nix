{ pkgs, config, lib, ... }:
with lib;
{
  imports = [
    ./modules/base.nix
    ./modules/installation-device.nix
    ./modules/uboot/hardkernel-uboot.nix
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
    platform = lib.systems.examples.aarch64-multiplatform.platform // {
      kernelTarget = "Image.gz";
      gcc = {
        arch = "armv8-a";
        extraArgs = [ "-mcrc" "-mcrypto" ];
      };
    };
  };

  nixpkgs.overlays = [
    (import ./modules/kernel/overlay.nix)
    (import ./modules/uboot/overlay.nix)
  ];

  #
  # Bootloader (UBoot, hardkernel)
  #
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = false;
  boot.loader.hardkernel-uboot.enable = true;

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
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };
}
