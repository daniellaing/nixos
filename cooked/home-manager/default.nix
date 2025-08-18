{lib, ...}: {
  imports = [
    ./git.nix
    ./hyprland.nix
    ./nix-index.nix
    ./R.nix
    ./tmux.nix
    ./zsh.nix
  ];

  home-manager.sharedModules = [
    {
      cooked = {
        git.enable = lib.mkDefault true;
        tmux.enable = lib.mkDefault true;
      };
    }
  ];
}
