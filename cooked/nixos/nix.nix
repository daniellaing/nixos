{
  lib,
  config,
  ...
}: let
  cfg = config.cooked.nix;
in {
  options.cooked.nix = {
    enable = lib.mkEnableOption "nix config";
  };

  config = lib.mkIf cfg.enable {
    nix = {
      settings = {
        experimental-features = ["nix-command" "flakes"];
        auto-optimise-store = true;
        use-xdg-base-directories = true;
        trusted-users = ["root" "@wheel"];
      };
      optimise = {
        automatic = true;
        dates = ["13:00" "20:00"];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
    };
  };
}
