{inputs, ...}: {
  flake-file.inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    nixpkgs-stable = {
      url = "github:NixOS/nixpkgs/nixos-26.05";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
    };
  };

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
