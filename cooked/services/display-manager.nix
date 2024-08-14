{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.cooked.display-manager;
  sddm-chili =
    pkgs.stdenv.mkDerivation
    rec {
      name = "sddm-chili-theme";
      pname = "sddm-chili-theme";
      version = "0.1.5";

      installPhase = ''
        mkdir -p $out
        cp -R ./* $out/
      '';

      src = pkgs.fetchFromGitHub {
        owner = "MarianArlt";
        repo = "sddm-chili";
        rev = "${version}";
        sha256 = "sha256-wxWsdRGC59YzDcSopDRzxg8TfjjmA3LHrdWjepTuzgw=";
      };
    };
in {
  options.cooked.display-manager = {
    enable = lib.mkEnableOption "the display manager";
  };

  config = lib.mkIf cfg.enable {
    services.displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
        autoNumlock = true;
        theme = "${sddm-chili}";
      };
    };

    # Dependencies
    environment.systemPackages = builtins.attrValues {
      inherit
        (pkgs.libsForQt5.qt5)
        qtquickcontrols
        qtgraphicaleffects
        ;
    };
  };
}
