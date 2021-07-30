let
  # Use patched version of nixpkgs to enable cross-compilation
  # to aarch64 so that we can build the SD-image on a non-ARM
  # platform.
  nixpkgs = import ./nixpkgs/cross-compilation.nix;
  nixos = import "${nixpkgs}/nixos" {
    configuration = { config, ... }: {
      imports = [
        ./modules/sd-image
      ];

      # set cross compiling
      nixpkgs.crossSystem.config = "aarch64-unknown-linux-gnu";

      # Use pinned packages
      # nixpkgs.pkgs = import "${nixpkgs}" {
      #   inherit (config.nixpkgs) config localSystem crossSystem;
      # };
    };
  };
in
nixos.config.system.build.sdImage // {
  inherit (nixos) pkgs system config;
}
