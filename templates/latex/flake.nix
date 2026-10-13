{
  description = throw "TODO: set flake description";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    flake-parts,
    self,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem = {pkgs, ...}: let
        tex =
          pkgs.texliveSmall.withPackages
          (ps:
            with ps; [
              scheme-minimal
              latex-bin
              latexmk
              texdoc
              # --- Dependencies
              fancyhdr
              geometry
              hyperref
              kpfonts
              nth
              # --- Transative dependencies
              amsmath # nth
              fontspec # kpfonts
              kpfonts-otf # kpfonts
              lualatex-math # nth
              realscripts # kpfonts
              unicode-math # nth
            ]).override {withDocs = true;};

        document = pkgs.callPackage ({
          stdenvNoCC,
          writableTmpDirAsHomeHook,
          version ? self.shortRev or "dirty",
        }:
          stdenvNoCC.mkDerivation {
            inherit version;
            pname = throw "TODO: set package name";
            src = self;

            SOURCE_DATE_EPOCH = "${toString self.lastModified}";

            buildInputs = [
              tex
              writableTmpDirAsHomeHook
            ];

            installPhase = ''
              mkdir -p $out
              cp ./*.pdf $out
            '';
          }) {};
      in {
        packages = {
          inherit document;
          default = document;
        };

        devShells.default = pkgs.mkShell {
          SOURCE_DATE_EPOCH = toString self.lastModified;
          packages = [tex];
        };
      };
    };
}
