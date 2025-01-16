{pkgs, ...}: {
  environment.systemPackages = builtins.attrValues {
    inherit
      (pkgs)
      # Utility
      git
      unzip
      wget
      ripgrep
      gnumake
      pinentry-curses
      gnupg
      # Secret management
      sops
      # Desktop
      libreoffice
      # Wayland
      wl-clipboard
      # Games
      prismlauncher # Minecraft
      ;
  };
}
