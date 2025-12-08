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

  config =
    lib.recursiveUpdate
    (lib.mkIf cfg.enable {
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
    })
    # If we have sops, use a github access token
    (lib.mkIf (cfg.enable && config.cooked.sops.enable) {
      nix.extraOptions = ''
        !include ${config.sops.secrets.nix-github-token.path}
      '';

      sops.secrets.nix-github-token = {
        mode = "0440";
      };
    });
}
