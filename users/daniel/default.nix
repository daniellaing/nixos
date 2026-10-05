{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./programs.nix
  ];

  # home-manager.users.daniel = {
  home = {
    username = "daniel";
    homeDirectory = "/home/daniel";
    stateVersion = "23.05";
    packages = builtins.attrValues {
      inherit
        (pkgs)
        btop
        # ferdium
        # musescore
        yt-dlp
        keepassxc
        pipes
        # nitch # Fetch utility
        vimix-icon-theme
        # ncdu
        ffmpeg-full
        imv
        vimv
        steam
        # sonic-visualiser
        # synthesia
        # ---   Fonts   ---
        alegreya
        alegreya-sans
        ;
    };

    pointerCursor = {
      enable = true;
      gtk.enable = true;
      package = pkgs.vimix-cursors;
      name = "Vimix-white-cursors";
    };
  };
  # };
}
