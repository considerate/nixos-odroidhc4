{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs";
    arapov-nixpkgs = {
      url = "github:arapov/nixpkgs/hardkernel";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };
  outputs = inputs: {
    overlays = {
      odroidhc4-uboot = final: prev:
        let uboot-nixpkgs = final.applyPatches {
          name = "nixpkgs-hc4-defconfig";
          src = inputs.arapov-nixpkgs;
          patches = [ ./hc4-uboot.patch ];
        };
        in
        {
          meson64-tools = final.callPackage "${uboot-nixpkgs}/pkgs/misc/meson64-tools" { };
          inherit (final.callPackage "${uboot-nixpkgs}/pkgs/misc/uboot" { })
            ubootOdroidC4
            ubootOdroidHC4;
          inherit (final.callPackage "${uboot-nixpkgs}/pkgs/misc/uboot/hardkernel-firmware.nix" { })
            firmwareOdroidC2
            firmwareOdroidC4;
        };
    };
    nixosModules = {
      odroidhc4 = {
        imports = [
          inputs.self.nixosModules.sd-image
          inputs.self.nixosModules.odroidhc4-uboot
        ];
      };
      sd-image = ({ lib, ... }: {
        imports = [
          # the 22.05 release unconditionally uses zstd which is broken on Linux 5.18
          # until https://github.com/NixOS/nixpkgs/pull/178830 is merged.
          "${inputs.nixpkgs-unstable}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-installer.nix"
        ];
        # Remove zfs from supported filesystems as it fails due to not being able to
        # build the kernel module
        boot.supportedFilesystems = lib.mkForce [
          "btrfs"
          "reiserfs"
          "vfat"
          "f2fs"
          "xfs"
          "ntfs"
          "cifs"
        ];
        sdImage.compressImage = false;
      });
      odroidhc4-uboot = ({ pkgs, lib, ... }: {
        # it doesn't come with a LICENSE... :(
        # @angerman, please add one.
        nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          "meson64-tools"
        ];
        nixpkgs.overlays = [ inputs.self.overlays.odroidhc4-uboot ];
      });
    };
    lib = {
      makeSdImage = nixos: nixos.pkgs.buildPackages.symlinkJoin {
        name = "build-${nixos.config.sdImage.imageName}";
        paths = [
          nixos.config.system.build.sdImage
          nixos.pkgs.ubootOdroidHC4
        ];
      };
    };
    nixosConfigurations = {
      example-hc4 = inputs.nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          inputs.self.nixosModules.odroidhc4
        ];
      };
    };
    packages.aarch64-linux =
      let
        pkgs = import inputs.nixpkgs {
          system = "aarch64-linux";
          overlays = [ inputs.self.overlays.odroidhc4-uboot ];
          config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [
            "meson64-tools"
          ];
        };
      in
      {
        uboot-odroid-hc4 = pkgs.ubootOdroidHC4;
      };
  };
}
