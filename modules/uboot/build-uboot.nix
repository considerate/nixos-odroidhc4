{ pkgs ? import (import ../nixpkgs) { }
}:
pkgs.pkgsCross.aarch64-multiplatform.callPackage ./upstream.nix {
  inherit (pkgs.callPackage ./hardkernel-firmware.nix { }) firmwareOdroidC4;
}
