{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
  };

  home = {
    sessionVariables = {
      EDITOR = "${pkgs.neovim}/bin/nvim";
      SUDO_EDITOR = "${pkgs.neovim}/bin/nvim";
    };
  };

  xdg = {
    desktopEntries = {
      neovim = {
        name = "Neovim";
        genericName = "Text Editor";
        comment = "Hyperextensible Vim-based text editor";
        exec = "${pkgs.neovim}/bin/nvim %U";
        terminal = true;
        categories = [ "Utility" "TextEditor" "ConsoleOnly" ];
        mimeType = [ "text/*" ];
      };
    };
    mimeApps.defaultApplications = {
      "text/*" = "neovim.desktop";
    };
  };
}
