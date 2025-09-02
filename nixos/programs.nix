{pkgs, ...}: {
  environment.systemPackages = builtins.attrValues {
    inherit
      (pkgs)
      # Utility
      pinentry-curses
      ;
  };
}
