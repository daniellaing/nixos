{ config, pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      neovim
    ];

    sessionVariables = {
      EDITOR = "${pkgs.neovim}/bin/nvim";
      SUDO_EDITOR = "${pkgs.neovim}/bin/nvim";
    };
  };
}
