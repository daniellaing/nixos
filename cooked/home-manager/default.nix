{lib, ...}: {
  imports = [
    ./git.nix
    ./hyprland.nix
    ./R.nix
    ./zsh.nix
  ];

  home-manager.sharedModules = [
    {
      cooked = {
        git.enable = lib.mkDefault true;
      };
    }
  ];
}
