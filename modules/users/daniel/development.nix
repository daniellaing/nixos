{config, ...}: {
  users.daniel.development = {pkgs, ...}: {
    imports = with config.modules; [
      development
    ];

    home-manager.users.daniel.home = {
      programs.git = {
        enable = true;
        settings = {
          user.email = "daniel@daniellaing.com";
          user.name = "Daniel Laing";
          signing = {
            key = "08218B96DC7385E5BB7CA535D2643BD213BC0FA8";
            signByDefault = true;
          };
          alias = {
            pa = "!git remote | ${pkgs.findutils}/bin/xargs -L1 git push --all";
            cpa = "!f() { git commit \"$@\" && git pa; }; f";
            lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date-order";
          };
          init = {
            defaultBranch = "master";
          };
        };
      };
    };
  };
}
