{inputs, ...}: {
  imports = [
    inputs.nix-colors.homeManagerModules.default

    ./email
    ./programs
    ./shell
    ./XF86Misc.nix
  ];

  colorScheme = inputs.nix-colors.colorSchemes.gruvbox-material-dark-medium;
}
