{ config, pkgs, ... }:

{
  environment = with pkgs; {
    systemPackages = [
      zsh
      zsh-powerlevel10k

      # Nice things
      lsd
      bat
    ];

    shells = [ zsh ];
    pathsToLink = [ "/share/zsh" ];
  };


  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    promptInit = "source ''${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };

}
