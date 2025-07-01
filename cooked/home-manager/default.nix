{lib, ...}: {
  imports = [
    ./git.nix
    ./hyprland.nix
    ./nix-index.nix
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
