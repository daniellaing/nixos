{ pkgs, ... }:

{
  services.locate = {
    enable = true;
    interval = "hourly";
    package = pkgs.plocate;
    pruneBindMounts = true;
  };
}
