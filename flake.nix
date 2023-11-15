{
  description = "Daniel's configuration flake";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, nix-colors, home-manager, hyprland, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      stable-pkgs = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations = {
        "nixos" = nixpkgs.lib.nixosSystem rec {
          inherit system;
          specialArgs = { inherit inputs; inherit stable-pkgs; };
          modules = [
            ./hosts/dellG5.nix
            ./nixos/configuration.nix

            hyprland.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.users.daniel = import ./daniel;
            }
          ];
        };
      };
    };
}
