{...}: let
  pname = "stag";
in {
  perSystem = {pkgs, ...}: {
    packages.${pname} =
      pkgs.stdenv.mkDerivation
      rec {
        inherit pname;
        version = "1.0";
        src = pkgs.fetchFromGitHub {
          rev = "v${version}";
          owner = "smabie";
          repo = pname;
          sha256 = "sha256-IWb6ZbPlFfEvZogPh8nMqXatrg206BTV2DYg7BMm7R4=";
        };

        outputs = [
          "out"
          "man"
        ];

        nativeBuildInputs = with pkgs; [
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
      };
  };
}
