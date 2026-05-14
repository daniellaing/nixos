{pkgs, ...}: {
  home-manager.sharedModules = [
    ({...}: {
      programs.git = {
        package = pkgs.stable.gitSVN;
      };
    })
  ];
}
