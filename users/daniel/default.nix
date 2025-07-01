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
    };
  };
}
