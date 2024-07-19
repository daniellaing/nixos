{pkgs, ...}: {
  home = {
    packages = builtins.attrValues {
      inherit
        (pkgs)
        sxiv
        ;
    };
  };

  xdg = {
    desktopEntries = {
      sxiv = {
        name = "SXIV";
        genericName = "Image Viewer";
        comment = "Simple X Image Viewer";
        exec = "sxiv %U";
        icon = "sxiv";
        categories = ["Graphics" "Viewer"];
        type = "Application";
        mimeType = ["image/*"];
      };
    };
    mimeApps.defaultApplications = {
      "image/*" = "sxiv.desktop";
    };
  };
}
