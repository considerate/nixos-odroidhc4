let
  # Use patched version of nixpkgs to enable cross-compilation
  # to aarch64 so that we can build the SD-image on a non-ARM
  # platform.
  nixpkgs = import ./nixpkgs;
  nixos = import "${nixpkgs}/nixos" {
    configuration = { config, ... }: {
      imports = [
        ./configuration.nix
        ./modules/sd-image
      ];

      # set cross compiling
      nixpkgs.crossSystem.config = "aarch64-unknown-linux-gnu";
    };
  };
in
nixos.config.system.build.sdImage // {
  inherit (nixos) pkgs system config;
}
