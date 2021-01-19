let nixpkgs = import ./nixpkgs.nix;
in
import "${nixpkgs}/nixos" {
  configuration = { ... }: {
    imports = [
      ./odroidhc4.nix
    ];
  };
}
