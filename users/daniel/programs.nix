{
  lib,
  pkgs,
  config,
  ...
}: {
  programs = {
    # ---   Home manager   ---
    home-manager.enable = true; # Let home manager manage itself
  };
}
