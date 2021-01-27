final: prev: {
  linux_hardkernel = final.callPackage ./kernel.nix {
    kernelPatches = [
      ({ name = "wip"; patch = ./wip.diff; })
    ];
  };
}
