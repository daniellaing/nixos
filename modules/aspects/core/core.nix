{
  config,
  lib,
  ...
}: {
  # Core system configuration module
  # The kind of stuff needed for even the most basic usability
  modules.core = {pkgs, ...}: {
    imports = with config.modules; [
      sudo
      nix
    ];

    config = lib.mkMerge [
      # ---   File systems   ---
      {
        # Will also include any file system types the host uses.
        # For example, if the host has a partition formatted as ext4,
        #   then ext4 will also be added to the supported file system types.
        # These are additional types.
        boot.supportedFilesystems = {
          exfat = lib.mkForce true;
        };
      }

      # ---   Fonts   ---
      {
        fonts.packages =
          (lib.filter lib.attrsets.isDerivation (lib.attrValues pkgs.nerd-fonts))
          ++ (with pkgs; [
            alegreya
            alegreya-sans
          ]);
      }

      # ---   Locale   ---
      (let
        timeZone = "Europe/London";
        locale = "en_GB.UTF-8";
      in {
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
      })

      # ---   Network   ---
      {
        networking = {
          networkmanager.enable = true;
          nftables.enable = true;
        };
      }

      # ---   Other essential packages   ---
      {
        environment.systemPackages = with pkgs; [
          pinentry-curses
        ];
      }
    ];
  };
}
