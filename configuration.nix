{ pkgs, lib, config, ... }:
let
  nixpkgs = import ./modules/nixpkgs;
in
{
  imports = [
    ./modules/odroidhc4
  ];
  # Pin nixpkgs version for better reproducibility
  nixpkgs.pkgs = lib.mkDefault (import "${nixpkgs}" {
    # The NixOS module appends nixpkgs.overlays to any overlays
    # specified here, hence we leave it out.
    inherit (config.nixpkgs) config localSystem crossSystem;
  });
}
