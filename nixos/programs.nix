{pkgs, ...}: {
  environment.systemPackages = builtins.attrValues {
    inherit
      (pkgs)
      # Utility
      unzip
      wget
      ripgrep
      gnumake
      pinentry-curses
      # Desktop
      libreoffice
      # Wayland
      wl-clipboard
      # Games
      prismlauncher # Minecraft

      ;
  };
}
