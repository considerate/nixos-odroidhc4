let
  # Use patched version of nixpkgs to enable cross-compilation
  # to aarch64 so that we can build the SD-image on a non-ARM
  # platform.
  nixpkgs = import ./modules/nixpkgs/cross-compilation.nix;
  nixos = import "${nixpkgs}/nixos" {
    configuration = { ... }: {
      imports = [
        ./modules/sd-image
      ];
    };
  };
in
nixos.config.system.build.sdImage // {
  inherit (nixos) pkgs system config;
}
