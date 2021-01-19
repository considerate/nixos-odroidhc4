let
  nixos = import ./nixos.nix;
in
nixos.config.system.build.sdImage // {
  inherit (nixos) pkgs system config;
}
