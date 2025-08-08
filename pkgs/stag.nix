{
  stdenv,
  fetchFromGitHub,
  ncurses,
  taglib,
  libz,
}:
stdenv.mkDerivation
rec {
  pname = "stag";
  version = "1.0";
  src = fetchFromGitHub {
    rev = "v${version}";
    owner = "smabie";
    repo = pname;
    sha256 = "sha256-IWb6ZbPlFfEvZogPh8nMqXatrg206BTV2DYg7BMm7R4=";
  };

  outputs = [
    "out"
    "man"
  ];

  nativeBuildInputs = [
    ncurses
    taglib
    libz
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp stag $out/bin

    mkdir -p $man/share/man/man1
    cp stag.1 $man/share/man/man1
  '';
}
