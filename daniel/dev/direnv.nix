{...}: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Quiet direnv
  home.sessionVariables.DIRENV_LOG_FORMAT = '''';
}
