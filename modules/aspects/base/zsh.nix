{
  modules.zsh = {pkgs, ...}: {
    environment = {
      shells = [pkgs.zsh];
      pathsToLink = ["/share/zsh"];
    };

    programs.zsh = {
      enable = true;
    };
  };
}
