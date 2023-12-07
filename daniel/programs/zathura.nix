{ config, pkgs, ... }:

{
  programs.zathura = {
    enable = true;
    mappings = {
      u = "scroll half-up";
      d = "scroll half-down";
      D = "toggle_page_mode";
      K = "zoom in";
      J = "zoom out";
      p = "print";
      g = "goto top";
    };
    options = {
      adjust-open = "best-fit";
      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      selection-clipboard = "clipboard";

      # SyncTeX
      synctex = true;
      synctex-editor-command = "code -g %{input}:%{line}";

      # Colour Scheme
      default-fg = "#CAD3F5";
      default-bg = "#181926";

      completion-bg = "#363A4F";
      completion-fg = "#CAD3F5";
      completion-highlight-bg = "#575268";
      completion-highlight-fg = "#CAD3F5";
      completion-group-bg = "#363A4F";
      completion-group-fg = "#8AADF4";

      statusbar-fg = "#CAD3F5";
      statusbar-bg = "#181926";

      notification-bg = "#363A4F";
      notification-fg = "#CAD3F5";
      notification-error-bg = "#363A4F";
      notification-error-fg = "#ED8796";
      notification-warning-bg = "#363A4F";
      notification-warning-fg = "#FAE3B0";

      inputbar-fg = "#CAD3F5";
      inputbar-bg = "#181926";

      recolor-lightcolor = "#181926";
      recolor-darkcolor = "#CAD3F5";

      index-fg = "#CAD3F5";
      index-bg = "#181926";
      index-active-fg = "#CAD3F5";
      index-active-bg = "#363A4F";

      render-loading-bg = "#181926";
      render-loading-fg = "#CAD3F5";

      highlight-color = "#575268";
      highlight-fg = "#F5BDE6";
      highlight-active-color = "#F5BDE6";
    };
  };
}
