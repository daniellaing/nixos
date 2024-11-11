{
  description = "Daniel's configuration flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    hyprland.url = "github:hyprwm/Hyprland";
    nix-colors.url = "github:misterio77/nix-colors";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
    };

    my_neovim = {
      url = "github:Bodleum/neovim";
    };
  };

  outputs = inputs @ {
    self,
    flake-parts,
    home-manager,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs self;} {
      systems = nixpkgs.lib.systems.flakeExposed;

      flake = {
        templates = import ./templates inputs;
        overlays = import ./overlays {inherit inputs;};

        nixosConfigurations = let
          mkHost = {
            hostName,
            system,
          }:
            nixpkgs.lib.nixosSystem rec {
              inherit system;
              specialArgs = {inherit inputs system self;};

              modules = [
                {networking = {inherit hostName;};}
                {
                  # Hyprland cache
                  nix.settings = {
                    substituters = ["https://hyprland.cachix.org"];
                    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
                  };
                }

                ./cooked

                ./hosts/${hostName}
                ./nixos/configuration.nix

                {
                  home-manager = {
                    useGlobalPkgs = true;
                    extraSpecialArgs = specialArgs;
                    users.daniel = import ./daniel;
                  };
                }

                home-manager.nixosModules.home-manager
              ];
            };
        in {
          dellG5 = mkHost {
            hostName = "dellG5";
            system = "x86_64-linux";
          };
          wsl = mkHost {
            hostName = "wsl";
            system = "x86_64-linux";
          };
        };
      };

      perSystem = {pkgs, ...}: {
        packages = import ./pkgs pkgs;
        formatter = pkgs.alejandra;
        devShells.default = pkgs.mkShell {
          packages = builtins.attrValues {
            inherit
              (pkgs)
              # wally-cli # For flashing moonlander keyboard
              
              nh
              ;
          };
        };
      };
    };
}
