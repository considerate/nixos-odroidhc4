let
  flake-compat-src = fetchTarball {
    url = https://github.com/edolstra/flake-compat/archive/b4a34015c698c7793d592d66adbab377907a2be8.tar.gz;
    sha256 = "sha256:1qc703yg0babixi6wshn5wm2kgl5y1drcswgszh4xxzbrwkk9sv7";
  };
  flake = import flake-compat-src { src = ./.; };
in
flake.defaultNix.packages.aarch64-linux.sd-image
