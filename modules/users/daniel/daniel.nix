{config, ...}: {
  users.daniel.core = {
    imports = with config.modules; [
      home-manager
    ];

    home-manager.users.daniel.home = {
      username = "daniel";
      homeDirectory = "/home/daniel";
    };
  };

  users.daniel.base = {
    imports = with config.users.daniel; [
      zsh
    ];

    home-manager.users.daniel = {
      programs.tmux = {
        enable = true;
        escapeTime = 10;
        keyMode = "vi";
        clock24 = true;
        extraConfig = ''
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
  };
}
