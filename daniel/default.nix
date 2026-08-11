{inputs, ...}: {
  imports = [
    inputs.nix-colors.homeManagerModules.default

    ./email
    ./programs
    ./scripts
    ./shell
    ./XF86Misc.nix
  ];

  # Let home manager manage itself
  programs.home-manager.enable = true;

  colorScheme = inputs.nix-colors.colorSchemes.gruvbox-material-dark-medium;
}
