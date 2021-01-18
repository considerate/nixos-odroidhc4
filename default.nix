let
  nixos = import <stable/nixos> {
    configuration = { ... }: {
      imports = [
        <stable/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix>
        ./odroidhc4.nix
      ];
    };
  };
in
nixos.config.system.build.sdImage // {
  inherit (nixos) pkgs system config;
}
