# Hardkernel NixOS for ODROID HC4

This is an unofficial installation configuration of [NixOS
22.05](https://nixos.org/manual/nixos/stable/) for the [Hardkernel
ODROID HC4](https://wiki.odroid.com/odroid-hc4/odroid-hc4)
microcomputer.

## Usage

The recommended usage is to import this repository as a [nix
flake](https://nixos.wiki/wiki/Flakes)

Create a flake.nix with the following content:

``` nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-22.05";
  inputs.nixos-odroidhc4.url = "github:considerate/nixos-odroidhc4/release-22.05";
  outputs = inputs: {
    packages.aarch64-linux = {
      uboot = inputs.nixos-odroidhc4.packages.aarch64-linux.uboot-odroid-hc4;
      sd-image = inputs.self.nixosConfigurations.nixos-hc4.config.system.build.sdImage;
    };
    nixosConfigurations = {
      nixos-hc4 = inputs.nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          inputs.nixos-odroidhc4.nixosModules.odroidhc4
          # add your own modules here...
        ];
      };
    };
  };
}
```

Build the SD image by running:

``` console
$ nix build .#packages.aarch64-linux.sd-image
```

Copy the built image to an SD-card with:

``` console
# dd if=result/sd-image/nixos-sd-image-*-aarch64-linux.img of=/dev/<DEVICE> status=progress bs=512K
```

Add the U-boot boot loader to the SD-card by building and running

``` console
$ nix build .#packages.aarch64-linux.uboot
$ ./result/sd_fusing.sh /dev/<DEVICE>
```
