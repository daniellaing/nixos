{ inputs, config, pkgs, system, ... }:
let
  neovim = inputs.my_neovim.packages.${system}.default;
in
{
  home = {
    packages = [ neovim ];
    sessionVariables = {
      EDITOR = "${neovim}/bin/nvim";
      SUDO_EDITOR = "${neovim}/bin/nvim";
    };
  };

  xdg = {
    desktopEntries = {
      neovim = {
        name = "Neovim";
        genericName = "Text Editor";
        comment = "Hyperextensible Vim-based text editor";
        exec = "${neovim}/bin/nvim %U";
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
