{
  lib,
  config,
  ...
}: let
  cfg = config.printing;
in {
  options.printing = {
    enable = lib.mkEnableOption ''
      Enable printing
    '';
  };

  config = lib.mkIf cfg.enable {
    services = {
      printing.enable = true;

      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };
  };
}
