{
  description = "Daniel's configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations = {
        "nixos" = nixpkgs.lib.nixosSystem rec {
          inherit system;
          specialArgs = { inherit hyprland; };
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
