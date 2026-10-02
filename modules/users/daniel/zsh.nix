{config, ...}: {
  users.daniel.zsh = {pkgs, ...}: {
    imports =
      (with config.modules; [
        zsh
      ])
      ++ (with config.users.daniel.modules; [
        shell-aliases
      ]);

    # Might need this
    # programs.zsh.promptInit = "source ''${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

    home-manager.users.daniel = {config, ...}: {
      home = {
        packages = [pkgs.zsh-powerlevel10k];
        sessionVariables = {
          GNUPGHOME = "${config.xdg.dataHome}/gnupg";
          LESSHISTFILE = "-";
          XCOMPOSEFILE = "${config.xdg.configHome}" + "/X11/xcompose";
          XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";
          CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
        };
      };

      programs = {
        zsh = let
          dotDir = "${config.xdg.configHome}/zsh";
        in {
          enable = true;
          syntaxHighlighting.enable = true;
          autosuggestion.enable = true;
          defaultKeymap = "viins";
          enableVteIntegration = true;
          history.path = "${config.xdg.stateHome}/zsh/zsh_history";
          envExtra = ''
            # ---   Colour man pages   ---
            export LESS_TERMCAP_mb=$'\e[1;32m'
            export LESS_TERMCAP_md=$'\e[1;32m'
            export LESS_TERMCAP_me=$'\e[0m'
            export LESS_TERMCAP_se=$'\e[0m'
            export LESS_TERMCAP_so=$'\e[01;33m'
            export LESS_TERMCAP_ue=$'\e[0m'
            export LESS_TERMCAP_us=$'\e[1;4;31m'
          '';
          initContent = ''
            # Set prompt
            [[ ! -f ${dotDir}/.p10k.zsh ]] || source ${dotDir}/.p10k.zsh

            setopt autocd
            setopt autopushd

            fancy-ctrl-z () {
              if [[ $#BUFFER -eq 0 ]]; then
                fg
                zle redisplay
              else
                zle push-input
              fi
            }
            zle -N fancy-ctrl-z
            bindkey '^Z' fancy-ctrl-z

            compinit -d ${config.xdg.cacheHome}/zsh/zcompdump-"$ZSH_VERSION"
          '';
        };
      };
    };
  };
}
