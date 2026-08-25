{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./programs.nix
  ];

  # home-manager.users.daniel = {
  cooked = {
    R.enable = true;
    zsh.enable = true;
    nix-index.enable = true;
    hyprland.enable = true;
    tmux = {
      conf = ''
        # Vim keys for pane navigation
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Vim keys in copy mode
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi V send-keys -X select-line
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

        # Open new panes and windows in same directory as current
        bind '"' split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        # Enable passthrough
        set -g allow-passthrough on
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM
      '';
    };
  };

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
