{
  description = "Daniel's configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    nur.url = "github:nix-community/NUR";
    nix-colors.url = "github:misterio77/nix-colors";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };


    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
    };

    my_neovim = {
      type = "path";
      path = "/home/daniel/neovim/";
    };

  };

  outputs = inputs:
    let
      system = "x86_64-linux";

      pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowAliases = false;
        };
      };

      overlay-stable = final: prev: {
        stable = import inputs.nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        };
      };

    in
    {
      nixosConfigurations = {
        "nixos" = inputs.nixpkgs.lib.nixosSystem rec {
          inherit system pkgs;
          specialArgs = { inherit inputs system; };

          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-stable inputs.nur.overlay ]; })
            ./hosts/dellG5.nix
            ./nixos/configuration.nix

            inputs.hyprland.nixosModules.default
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.users.daniel = import ./daniel;
            }
          ];
        };
      };

      templates = import ./templates inputs;

      devShells.${system}.default = pkgs.mkShell
        {
          packages = with pkgs; [
            rnix-lsp
          ];
        };
    };
}
