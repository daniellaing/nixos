{
  nixpkgs,
  nixpkgs-stable,
  my_neovim,
  ...
}: {
  default = nixpkgs.lib.composeManyExtensions [
    # Stable packages
    (final: prev: {
      stable = import nixpkgs-stable {
        system = prev.system;
        config = {allowUnfree = true;};
        overlays = [];
      };
    })

    # Adds packages packaged in this flake
    (final: prev:
      import ../pkgs {pkgs = final;}
      // {
        scripts = import ../pkgs/scripts {pkgs = final;};
      })

    (
      final: prev: {
        my_neovim = my_neovim.packages.${prev.system}.default;
      }
    )
  ];
}
