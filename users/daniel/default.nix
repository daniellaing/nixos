{lib, ...}: {
  home-manager.users.daniel = {
    cooked = {
      R.enable = true;
      zsh.enable = true;
      nix-index.enable = true;
      hyprland.enable = true;
    };

    programs = {
      git = {
        userEmail = lib.mkDefault "daniel@daniellaing.com";
        userName = "Daniel Laing";
        signing = {
          key = lib.mkDefault "08218B96DC7385E5BB7CA535D2643BD213BC0FA8";
          signByDefault = true;
        };
      };

      tmux.extraConfig = ''
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi V send-keys -X select-line
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      '';
    };
  };
}
