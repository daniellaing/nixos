{ inputs, config, pkgs, lib, ... }:

{
  home = {
    username = "daniel";
    homeDirectory = "/home/daniel";
    stateVersion = "23.05";
    packages = with pkgs; [
      btop
      ferdium
      musescore
      yt-dlp
      keepassxc
      pipes
      nitch # Fetch utility
      vimix-icon-theme
    ];
  };

  imports =
    [
      inputs.nix-colors.homeManagerModules.default

      ./email
      ./menus
      ./programs
      ./shell
    ];

  # Let home manager manage itself
  programs.home-manager.enable = true;

  colorScheme = inputs.nix-colors.colorSchemes.gruvbox-material-dark-medium;
  # colorScheme = {
  #   slug = "borealis";
  #   name = "Borealis";
  #   author = "MerrinX";
  #   colors = {
  #     base00 = "282c34";
  #     base01 = "353b45";
  #     base02 = "3E2D5C";
  #     base03 = "545862";
  #     base04 = "565c64";
  #     base05 = "abb2bf";
  #     base06 = "b6bdca";
  #     base07 = "c8ccd4";
  #     base08 = "e06c75";
  #     base09 = "d19a66";
  #     base0A = "e5c07b";
  #     base0B = "98c379";
  #     base0C = "56b6c2";
  #     base0D = "61afef";
  #     base0E = "c678dd";
  #     base0F = "be5046";
  #   };
  # };
}
