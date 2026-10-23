{
  config,
  lib,
  ...
}: {
  # Base stuff for a graphical interface
  users.daniel.gui = {pkgs, ...}: {
    imports =
      (with config.modules; [xf86])
      ++ (with config.users.daniel; [
        dunst
        firefox
        kitty
        mangowm
        mpv
        waybar
        zathura
      ]);

    home-manager.sharedModules = [
      {
        options.openInTerminal = lib.mkOption {
          type = lib.types.uniq (lib.types.functionTo lib.types.str);
          description = "Runs the given command in the configured terminal emulator";
        };
      }
    ];

    home-manager.users.daniel = {config, ...}: {
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

      programs.rofi = {
        enable = true;
        settings = {
          terminal = config.xf86.terminal.cmd;
        };
      };
    };
  };
}
