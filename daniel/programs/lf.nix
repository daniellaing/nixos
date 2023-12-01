{ pkgs, ... }:

{
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
    hash = "sha256-QbWr5FxJZ5cJqS4zg+qyNK8JUG6SdLmaFoBuFXi0q0M=";
  };
}
