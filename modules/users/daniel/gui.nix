{
  config,
  lib,
  ...
}: {
  # Base stuff for a graphical interface
  users.daniel.gui = {pkgs, ...}: {
    imports = with config.users.daniel; [
      dunst
      firefox
      mpv
      zathura
    ];

    home-manager.sharedModules = [
      {
        options.openInTerminal = lib.mkOption {
          type = lib.types.uniq (lib.types.functionTo lib.types.str);
          description = "Runs the given command in the configured terminal emulator";
        };
      }
    ];

    home-manager.users.daniel = {
      home = {
        pointerCursor = {
          enable = true;
          gtk.enable = true;
          package = pkgs.vimix-cursors;
          name = "Vimix-white-cursors";
        };

        packages = with pkgs; [
          imv
        ];
      };
    };
  };
}
