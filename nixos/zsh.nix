{pkgs, ...}: {
  environment = {
    systemPackages = builtins.attrValues {
      inherit
        (pkgs)
        zsh-powerlevel10k
        ;
    };
    shells = [pkgs.zsh];
    pathsToLink = ["/share/zsh"];
  };

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    promptInit = "source ''${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };
}
