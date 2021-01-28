let
  src = import ./default.nix;
  pkgs = import src { };
  patched-src = pkgs.applyPatches {
    inherit src;
    name = "nixpkgs-patched";
    patches = [
      # Disable gobject-introspection during cross-compilation
      (pkgs.fetchpatch {
        url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/108173.patch";
        sha256 = "0hx4xznqb8cx7c87lirlwbj4n7wzgvhv0zkldhxvi60xzw3mkcch";
      })
      # Patch mailutils (dependency of zfs) for cross-compilation
      (pkgs.fetchpatch {
        url = "https://github.com/NixOS/nixpkgs/commit/a4c39a624c9658beb96c95fa7947aed988ed7c59.patch";
        sha256 = "1cf30vhw5zrigdpz85k02h3vx826wxlrjqk775jja35gf3wbzxh9";
      })
      (pkgs.fetchpatch {
        url = "https://github.com/NixOS/nixpkgs/commit/f7ec01ab6c91b30cc1df54cd49151e401b3fdcb0.patch";
        sha256 = "06igyijq4b1jg883k3p9w0fl8z55m73v7r7zdkdbj9sddl4i4q6d";
      })
    ];
  };
in
patched-src
