{pkgs, ...}: {
  programs.lf = {
    enable = true;
    settings = {
      preview = true;
      hidden = true;
      icons = true;
      ignorecase = true;
    };
  };

  xdg.configFile."lf/icons".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/gokcehan/lf/master/etc/icons.example";
    hash = "sha256-c0orDQO4hedh+xaNrovC0geh5iq2K+e+PZIL5abxnIk=";
  };
}
