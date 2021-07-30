let
  nixpkgs = import ./modules/nixpkgs;
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
