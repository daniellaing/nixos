{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    settings = {
      input = {
        kblayout = [ gb us ];
        kbvariant = [ uk dvorak ];
        kboptions = caps:swapescape,grp:ctrls_toggle;
      };
    };
  };

  # Emergency terminal
  home.packages = [
    pkgs.kitty
  ];
}
