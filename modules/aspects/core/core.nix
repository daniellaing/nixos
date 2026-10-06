{
  config,
  lib,
  ...
}: {
  # Core system configuration module
  # The kind of stuff needed for even the most basic usability
  modules.core = {pkgs, ...}: let
    timeZone = "Europe/London";
    locale = "en_GB.UTF-8";

    modules = with config.modules; [
      sudo
      nix
    ];
  in {
    imports = [] ++ modules;

    # ---   Fonts   ---
    fonts.packages =
      (lib.filter lib.attrsets.isDerivation (lib.attrValues pkgs.nerd-fonts))
      ++ (with pkgs; [
        alegreya
        alegreya-sans
      ]);

    # ---   Locale   ---
    time = {inherit timeZone;};
    i18n = {
      defaultLocale = locale;
      extraLocaleSettings = {
        LC_ADDRESS = locale;
        LC_IDENTIFICATION = locale;
        LC_MEASUREMENT = locale;
        LC_MONETARY = locale;
        LC_NAME = locale;
        LC_NUMERIC = locale;
        LC_PAPER = locale;
        LC_TELEPHONE = locale;
        LC_TIME = locale;
      };
    };
    console.keyMap = "uk";

    # ---   Network   ---
    networking = {
      networkmanager.enable = true;
      nftables.enable = true;
    };

    # ---   Other essential packages   ---
    environment.systemPackages = with pkgs; [
      pinentry-curses
    ];
  };
}
