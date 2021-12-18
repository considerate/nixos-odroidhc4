{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/382039c05a16827a7f0731183e862366b66b422f";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };
  outputs = inputs: {
    nixosModules = {
      sd-image = import ./modules/sd-image;
      odroidhc4 = import ./modules/odroidhc4;
      example = import ./modules/example;
      # in case you want to depend on the uboot module directly use this output
      hardkernel-uboot = import ./modules/uboot/hardkernel-uboot.nix;
    };
    nixosConfigurations = inputs.flake-utils.lib.eachDefaultSystem (system: {
      sd-image = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({
            nixpkgs.crossSystem = {
              config = "aarch64-unknown-linux-gnu";
            };
          })
          inputs.self.nixosModules.sd-image
        ];
      };
    });
  };
}
