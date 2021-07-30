let
  src = import ./default.nix;
  pkgs = import src { };
  patched-src = pkgs.applyPatches {
    inherit src;
    name = "nixpkgs-patched";
    patches = [
    ];
  };
in
patched-src
