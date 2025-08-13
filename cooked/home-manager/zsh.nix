{
  config,
  lib,
  pkgs,
  ...
}: let
  zsh_enabled = builtins.any (cfg: cfg.programs.zsh.enable) (builtins.attrValues config.home-manager.users);
in
  lib.mkMerge [
    (lib.mkIf
      zsh_enabled
      {
        environment = {
          systemPackages = builtins.attrValues {
            inherit
              (pkgs)
              zsh-powerlevel10k
              ;
          };
          shells = [pkgs.zsh];

          # ZSH completion
          # Added to allow completion of system packages
          pathsToLink = ["/share/zsh"];
        };

        programs.zsh = {
          enable = true;
          syntaxHighlighting.enable = true;
          promptInit = "source ''${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        };
      })
    {
      home-manager.sharedModules = [
        ({config, ...}: let
          cfg = config.cooked.zsh;
        in {
          options.cooked.zsh = {
            enable = lib.mkEnableOption "user zsh config";
          };

          config = lib.mkIf cfg.enable {
            programs.zsh = let
              dotDir = "${config.xdg.configHome}/zsh";
            in {
              inherit dotDir;
              enable = true;
              autosuggestion.enable = true;
              defaultKeymap = "viins";
              enableVteIntegration = true;
              history.path = "${config.xdg.stateHome}/zsh/zsh_history";
              envExtra = ''
                # ---   Cleanup   ---
                # export GNUPGHOME="''${XDG_DATA_HOME:-$HOME/.local/share}/gnupg"

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
        })
      ];
    }
  ]
