{config, ...}: {
  users.daniel.zsh = {pkgs, ...}: {
    imports =
      (with config.modules; [
        zsh
      ])
      ++ (with config.users.daniel; [
        shell-aliases
      ]);

    users.users.daniel.shell = pkgs.zsh;
    home-manager.users.daniel = {
      config,
      lib,
      ...
    }: let
      dotDir = "${config.xdg.configHome}/zsh";
      cacheDir = "${config.xdg.cacheHome}/zsh";
      stateDir = "${config.xdg.stateHome}/zsh";
    in {
      home = {
        sessionVariables = {
          GNUPGHOME = "${config.xdg.dataHome}/gnupg";
          LESSHISTFILE = "-";
          CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
        };

        # Create directories we will need
        activation.prepareZshCompletionCache = lib.hm.dag.entryAfter ["writeBoundary"] ''
          run ${lib.getExe' pkgs.coreutils "mkdir"} -p -m 0700 -- ${lib.escapeShellArg cacheDir}
          run ${lib.getExe' pkgs.coreutils "mkdir"} -p -m 0700 -- ${lib.escapeShellArg stateDir}
        '';
      };

      programs = {
        zsh = {
          inherit dotDir;
          enable = true;
          syntaxHighlighting.enable = true;
          autosuggestion.enable = true;
          defaultKeymap = "viins";
          enableVteIntegration = true;
          history.path = "${stateDir}/zsh_history";
          completionInit = "autoload -Uz compinit && compinit -d ${cacheDir}/zcompdump-${config.programs.zsh.package.version}";
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

          initContent = lib.mkMerge [
            (lib.mkOrder 500 ''
              if [[ -r "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
                source "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh"
              fi

              (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"
            '')

            ''
              # Set prompt
              source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
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

            ''
          ];
        };
      };
    };
  };
}
