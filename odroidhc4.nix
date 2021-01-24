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

  #
  # Bootloader (UBoot, extlinux)
  #
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible = {
    enable = true;
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

  sdImage = {
    compressImage = false;
    firmwareSize = 40;
    populateFirmwareCommands =
      let boot-ini = pkgs.writeText "boot.ini" ''
        ODROIDC4-UBOOT-CONFIG

        setenv bootlabel "Hardkernel NixOS 20.09"

        setenv board "odroidc4"
        setenv display_autodetect "true"
        setenv hdmimode "1080p60hz"
        setenv monitor_onoff "false" # true or false
        setenv overscan "100"
        setenv sdrmode "auto"
        setenv voutmode "hdmi"
        setenv disablehpd "false"
        setenv cec "true"
        setenv disable_vu7 "true"
        setenv max_freq_a55 "1908"    # 1.908 GHz, default value
        setenv maxcpus "4"
        setenv enable_wol "0"

        # Set load addresses
        setenv dtb_loadaddr "0x10000000"
        setenv dtbo_addr_r "0x11000000"
        setenv k_addr "0x1100000"
        setenv loadaddr "0x1B00000"
        #setenv initrd_loadaddr "0x3700000"
        #setenv initrd_loadaddr "0xfffffff2"
        setenv initrd_loadaddr "0x00000000"

        if test "''${variant}" = "hc4"; then
           setenv max_freq_a55 "1800"
        fi

        load mmc ''${devno}:1 ''${loadaddr} config.ini \
          && ini generic ''${loadaddr}
        if test "x''${overlay_profile}" != "x"; then
          ini overlay_''${overlay_profile} ''${loadaddr}
        fi

        setenv condev "console=ttyS0,115200n8"   # on both


        ### Normal HDMI Monitors
        if test "''${display_autodetect}" = "true"; then hdmitx edid; fi
        if test "''${hdmimode}" = "custombuilt"; then setenv cmode "modeline=''${modeline}"; fi
        if test "''${cec}" = "true"; then setenv cec_enable "hdmitx=cec3f"; fi
        if test "''${disable_vu7}" = "false"; then setenv hid_quirks "usbhid.quirks=0x0eef:0x0005:0x0004"; fi

        # Boot Args
        setenv bootargs "root=root=/dev/mmcblk''${devno}p2  rootwait rw ''${condev} ''${amlogic} no_console_suspend fsck.repair=yes net.ifnames=0 elevator=noop hdmimode=''${hdmimode} cvbsmode=576cvbs max_freq_a55=''${max_freq_a55} maxcpus=''${maxcpus} voutmode=''${voutmode} ''${cmode} disablehpd=''${disablehpd} cvbscable=''${cvbscable} overscan=''${overscan} ''${hid_quirks} monitor_onoff=''${monitor_onoff} logo=osd0,loaded ''${cec_enable} sdrmode=''${sdrmode} enable_wol=''${enable_wol} systemConfig=${config.system.build.toplevel} init=${config.system.build.toplevel}/init"

        # Load kernel, dtb and initrd
        load mmc ''${devno}:1 ''${k_addr} Image.gz
        load mmc ''${devno}:1 ''${dtb_loadaddr} amlogic/meson64_odroid''${variant}.dtb
        load mmc ''${devno}:1 ''${initrd_loadaddr} uInitrd
        fdt addr ''${dtb_loadaddr}

        if test "x{overlays}" != "x"; then
          fdt resize ''${overlay_resize}
          for overlay in ''${overlays}; do
          load mmc ''${devno}:1 ''${dtbo_addr_r} amlogic/overlays/''${board}/''${overlay}.dtbo \
              && fdt apply ''${dtbo_addr_r}
          done
        fi

        # unzip the kernel
        unzip ''${k_addr} ''${loadaddr}

        # boot
        booti ''${loadaddr} ''${initrd_loadaddr} ''${dtb_loadaddr}
      '';
      in
      ''
        cp ${boot-ini} firmware/boot.ini
        cp ${./config.ini} firmware/config.ini
        cp -r ${linux_hardkernel}/Image.gz ${linux_hardkernel}/dtbs/amlogic firmware/
        cp ${config.system.build.toplevel}/initrd initrd.gz
        gzip -d initrd.gz
        ${pkgs.buildPackages.ubootTools}/bin/mkimage -A arm64 -O linux -T ramdisk -C none -d initrd uInitrd
        mv uInitrd firmware/
      '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDiRIiaJvpr2JtisMaTN7QhYENBUQ9r/WzthEuMcAXNetCHbP5Ug74j3YA4DcI3ajhenqc3BGQPP0lh2AHZ0uriFqkxMCezSfu0+gSygzUUZh2lJfEnnPuv9J6BKWEtu1cr/pZQpfyye5RfgjuYe+v3aY14InDT0LW/UMR32EPK9yhuG0s+gkMRuqfF8HCUEgA6xDzg67CY9KfCu2JuekCHJJzdTSERkEkejUCd3cnlV63eUdo+SDrFdfsOR5CIpKPq27TpRAvqTvjuILLlG8mc1O/EUdf8P13Y3SF1itiTGBMCnmN/X9hZfzKL4x8skhqWg6sD2p+O8lbmfdI1FV0Gc6RZvHXJHJjXHIVAu1OSqduOMlPVNPfxTfXQh6VTexPAiPR77EJt2X2b6bL4HvgZxTNPh0cZTbpPcbDRmk8AuHfV6cDWNFjMIDytLeleL68g1cedWM1wNnJh4sy76CvY61QKvoNpcl+d8xwDDDDSPPhSGE8MXwEXgqsnrZTqoKc= considerate@considerate-nixos"
  ];

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

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };
}
