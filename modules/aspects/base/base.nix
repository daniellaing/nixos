{
  config,
  moduleWithSystem,
  ...
}: {
  # Base system configuration module
  modules.base = moduleWithSystem ({
    self',
    pkgs,
    ...
  }: {
    imports = with config.modules; [
      sops
      syncthing
      xf86
    ];

    # ---   GnuPG   ---
    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-curses;
    };

    # ---   Locate   ---
    services.locate = {
      enable = true;
      interval = "hourly";
      pruneBindMounts = true;
    };

    # ---   Printing   ---
    services = {
      printing.enable = true;

      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };

    # ---   Other packages   ---
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
  });
}
