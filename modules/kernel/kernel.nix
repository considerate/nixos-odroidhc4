{ stdenv
, fetchFromGitHub
, linuxManualConfig
, ...
}:

linuxManualConfig rec {
  inherit stdenv;

  version = "5.11.16";

  # modDirVersion needs to be x.y.z.
  modDirVersion = "5.11.16";

  # branchVersion needs to be x.y.
  extraMeta.branch = "5.11";
  extraMeta.platforms = [ "aarch64-linux" ];
  # TODO: are these needed?

  src = fetchFromGitHub {
    owner = "tobetter";
    repo = "linux";
    rev = "ddd1bcb1f4d743a8f46b767c7ffc6bfc13f407bc";
    sha256 = "186jj25bv7p4b8xjsbyiq7j3rnxwpb6q04h16gbm2gql2imy0d5r";
  };

  # Strip down kernel
  configfile = ./config;

  # Needs to be set when building with manual config
  allowImportFromDerivation = true;
}
