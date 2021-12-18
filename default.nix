{ system ? builtins.currentSystem }:
let
  flake-compat-src = fetchTarball {
    url = https://github.com/edolstra/flake-compat/archive/master.tar.gz;
    sha256 = "sha256:0jm6nzb83wa6ai17ly9fzpqc40wg1viib8klq8lby54agpl213w5";
  };
  flake = import flake-compat-src { src = ./.; };
in
flake.defaultNix.nixosConfigurations.sd-image.${system}.config.system.build.sdImage
