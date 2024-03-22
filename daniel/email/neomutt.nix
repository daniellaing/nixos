{
  config,
  pkgs,
  ...
}: {
  xdg = {
    desktopEntries = {
      neomutt = {
        name = "Neomutt";
        genericName = "Email Client";
        comment = "Read and send emails";
        exec = "${pkgs.neomutt}/bin/neomutt %U";
        icon = "mutt";
        terminal = true;
        categories = ["Network" "Email" "ConsoleOnly"];
        mimeType = ["x-scheme-handler/mailto"];
      };
    };
    mimeApps.defaultApplications = {
      "x-scheme-handler/mailto" = "neomutt.desktop";
    };
  };

  programs.neomutt = {
    enable = true;
    editor = "$EDITOR -- -c 'set syntax=mail fileencoding=utf-8 ft=mail'";
    binds = [
      # Remove some default keybinds
      # {
      #   action = "noop";
      #   key = "i";
      #   map = [ "index" "pager" ];
      # }
    ];
  };

  xdg.configFile."neomutt" = {
    source = ./neomutt;
    recursive = true;
  };
}
