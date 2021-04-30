{ pkgs, config, lib, ... }:
with lib;
{
  imports = [
    ../base.nix
    ../uboot-script
  ];
  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_tobetter;

  boot.initrd.availableKernelModules = [ ];

  nixpkgs.overlays = [
    (import ../kernel/overlay.nix)
  ];

  # Bootloader (u-boot is installed, generate /boot/boot.scr for it)
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = false;
  boot.loader.hardkernel-uboot.enable = true;

  # DTB file to use. This one is present in the hardkernel and tobetter tree
  # only. For real mainline kernel use "amlogic/meson-sm1-odroid-hc4.dtb"
  # instead, and some peripherals might not work.
  hardware.deviceTree.name = "amlogic/meson64_odroidhc4.dtb";

  # SSH
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Add public SSH key to root user's authorized_keys file
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDiRIiaJvpr2JtisMaTN7QhYENBUQ9r/WzthEuMcAXNetCHbP5Ug74j3YA4DcI3ajhenqc3BGQPP0lh2AHZ0uriFqkxMCezSfu0+gSygzUUZh2lJfEnnPuv9J6BKWEtu1cr/pZQpfyye5RfgjuYe+v3aY14InDT0LW/UMR32EPK9yhuG0s+gkMRuqfF8HCUEgA6xDzg67CY9KfCu2JuekCHJJzdTSERkEkejUCd3cnlV63eUdo+SDrFdfsOR5CIpKPq27TpRAvqTvjuILLlG8mc1O/EUdf8P13Y3SF1itiTGBMCnmN/X9hZfzKL4x8skhqWg6sD2p+O8lbmfdI1FV0Gc6RZvHXJHJjXHIVAu1OSqduOMlPVNPfxTfXQh6VTexPAiPR77EJt2X2b6bL4HvgZxTNPh0cZTbpPcbDRmk8AuHfV6cDWNFjMIDytLeleL68g1cedWM1wNnJh4sy76CvY61QKvoNpcl+d8xwDDDDSPPhSGE8MXwEXgqsnrZTqoKc= considerate@considerate-nixos"
  ];

  # DNS
  services.resolved.enable = true;
  services.resolved.dnssec = "false";

  # set a default root password
  users.users.root.initialPassword = "toor";

  # Install cachix binary cache for faster installations
  nix = {
    binaryCaches = [
      "https://considerate.cachix.org"
    ];
    binaryCachePublicKeys = [
      "considerate.cachix.org-1:qI1u8kAd+aovY5qxCgby2OJhfp7ZMVwCt6JyT2V6rfM="
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };
}
