{
  inputs,
  config,
  pkgs,
  lib,
  osConfig,
  ...
}: {
  nix.settings = osConfig.nix.settings;
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
      ncdu
      ffmpeg
      imv
      vimv
      steam
      sonic-visualiser
      synthesia

      # Fonts
      alegreya
      alegreya-sans
    ];

    pointerCursor = {
      gtk.enable = true;
      package = pkgs.vimix-cursors;
      name = "Vimix-white-cursors";
    };
  };

  imports = [
    inputs.nix-colors.homeManagerModules.default

    ./dev
    ./email
    ./menus
    ./programs
    ./scripts
    ./shell
    ./XF86Misc.nix
  ];

  # Let home manager manage itself
  programs.home-manager.enable = true;

  colorScheme = inputs.nix-colors.colorSchemes.gruvbox-material-dark-medium;
}
