{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userEmail = "daniel@daniellaing.com";
    userName = "Daniel";
    signing = {
      key = "08218B96DC7385E5BB7CA535D2643BD213BC0FA8";
      signByDefault = true;

    };
    aliases = {
      pa = "!git remote | ${pkgs.findutils}/bin/xargs -L1 git push --all";
      cpa = "!f() { git commit \"$@\" && git pa; }; f";
    };
    extraConfig = {
      init = {
        defaultBranch = "master";
      };
    };
  };
}
