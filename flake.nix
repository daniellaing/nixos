{
  description = "Daniel's configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    nur.url = "github:nix-community/NUR";
    nix-colors.url = "github:misterio77/nix-colors";
    flake-parts.url = "github:hercules-ci/flake-parts";

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

    hyprland = {
      url = "https://github.com/hyprwm/Hyprland";
      type = "git";
      submodules = true;
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
                ./common

                ./hosts/${hostName}
                ./nixos/configuration.nix

                home-manager.nixosModules.home-manager
                {
                  home-manager = {
                    useGlobalPkgs = true;
                    extraSpecialArgs = specialArgs;
                    users.daniel = import ./daniel;
                  };
                }

                inputs.hyprland.nixosModules.default
              ];
            };
        in {
          dellG5 = mkHost {
            hostName = "dellG5";
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
              nh
              # wally-cli # For flashing moonlander keyboard
              
              ;
          };
        };
      };
    };
}
