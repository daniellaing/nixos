{
  modules.development = {pkgs, ...}: {
    programs.direnv = {
      enable = true;
      silent = true;
    };

    programs.git = {
      enable = true;
    };

    environment.systemPackages = with pkgs; [
      gnumake
    ];
  };
}
