{ stdenv, python2, python3 }:
stdenv.mkDerivation {
  name = "meson64-tools";
  nativeBuildInputs = [ python2 python3 ];
  src = builtins.fetchTarball {
    url = "https://github.com/angerman/meson64-tools/archive/a2d57d11fd8b4242b903c10dca9d25f7f99d8ff0.tar.gz";
    sha256 = "1487cr7sv34yry8f0chaj6s2g3736dzq0aqw239ahdy30yg7hb2v";
  };

  preBuild = ''
    patchShebangs .
    patchShebangs ./mbedtls/scripts/generate_psa_constants.py
  '';
  makeFlags = [ "PREFIX=$(out)/bin" ];
}
