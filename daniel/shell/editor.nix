{pkgs, ...}: {
  home = {
    packages = [pkgs.my_neovim];
    sessionVariables = {
      EDITOR = "${pkgs.my_neovim}/bin/nvim";
      SUDO_EDITOR = "${pkgs.my_neovim}/bin/nvim";
    };
  };

  xdg = {
    desktopEntries = {
      neovim = {
        name = "Neovim";
        genericName = "Text Editor";
        comment = "Hyperextensible Vim-based text editor";
        exec = "${pkgs.my_neovim}/bin/nvim %U";
        terminal = true;
        categories = ["Utility" "TextEditor" "ConsoleOnly"];
        mimeType = ["text/*"];
      };
    };
    mimeApps.defaultApplications = {
      "text/*" = "neovim.desktop";
    };
  };
}
