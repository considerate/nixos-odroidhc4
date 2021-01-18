{ stdenv
, buildPackages
, fetchFromGitHub
, perl
, buildLinux
, libelf
, utillinux
, lib
, ...
}@args:

buildLinux (args // rec {
  version = "4.9.241-107";

  # modDirVersion needs to be x.y.z.
  modDirVersion = "4.9.241";

  # branchVersion needs to be x.y.
  extraMeta.branch = "4.9";

  # src = ./linux;
  src = fetchFromGitHub {
    owner = "hardkernel";
    repo = "linux";
    rev = version;
    sha256 = "1f004ahbj0x5nmr0240jdv7v6ssgbxd53ivsv7gra87hcm00hbn3";
  };

  defconfig = "odroidg12_defconfig";

  autoModules = false;
  structuredExtraConfig = with lib.kernel; {
    NR_CPUS = lib.mkForce (freeform "8");
  };

  extraMeta.platforms = [ "aarch64-linux" ];

} // (args.argsOverride or { }))
