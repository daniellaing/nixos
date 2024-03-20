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

    disko = {
      url = "github:nix-community/disko";
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
      url = "github:Bodleum/neovim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

  };

  outputs = inputs:
    let
      inherit (inputs.self) outputs;
      system = "x86_64-linux";

      pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowAliases = false;
        };
      };
    in
    {
      overlays = import ./overlays { inherit inputs system; };

      nixosConfigurations = {
        "nixos" = inputs.nixpkgs.lib.nixosSystem rec {
          inherit system pkgs;
          specialArgs = { inherit inputs outputs system; };

          modules = [
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
            wally-cli
          ];

        };
    };
}
