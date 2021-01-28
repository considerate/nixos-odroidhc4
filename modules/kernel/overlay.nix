final: prev: {
  linux_hardkernel = final.callPackage ./kernel.nix {
    kernelPatches = [
      # The kernel fails to cross-compile due to:
      # 1. warnings caused by different interpretation of function pointers
      # 2. NR_CPUS causing stack overflows when allocating cpu_topology
      # 3. The IRBLASTER module not registering syscalls correctly

      # The following patch makes the above warnings non-errors, decreases NR_CPUS to 4 and disables the IRBLASTER module.
      ({ name = "hardkernel-patches"; patch = ./kernel.diff; })
    ];
  };
}
