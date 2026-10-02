{inputs, ...}: {
  modules.nix = {
    imports = [inputs.nix-index-database.nixosModules.nix-index];

    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = ["nix-command" "flakes"];
        trusted-users = ["root" "@wheel"];
        use-xdg-base-directories = true;
      };
      optimise = {
        automatic = true;
        dates = ["13:00" "20:00"];
      };
      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 14d";
      };
    };

    nixpkgs.config.allowUnfree = true;

    programs.nix-index-database = {
      enable = true;
      comma.enable = true;
    };
  };
}
