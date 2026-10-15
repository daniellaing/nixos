{
  config,
  lib,
  moduleWithSystem,
  ...
}: {
  # Base system configuration module
  modules.base = lib.mkMerge [
    {
      imports = with config.modules; [
        sops
        syncthing
        xf86
      ];
    }

    # ---   GnuPG   ---
    (
      moduleWithSystem (
        {pkgs, ...}: {
          programs.gnupg.agent = {
            enable = true;
            pinentryPackage = pkgs.pinentry-curses;
          };
        }
      )
    )

    # ---   Locate   ---
    {
      services.locate = {
        enable = true;
        interval = "hourly";
        pruneBindMounts = true;
      };
    }

    # ---   Printing   ---
    {
      services = {
        printing.enable = true;

        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
      };
    }

    # ---   Other packages   ---
    (moduleWithSystem ({
      self',
      pkgs,
      ...
    }: {
      environment.systemPackages =
        (with pkgs; [
          curl
          ripgrep
          unzip
          wget
        ])
        ++ (with self'.packages; [
          configure
        ]);
    }))
  ];
}
