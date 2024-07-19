{pkgs, ...}: {
  programs.mpv = {
    enable = true;
    scripts = builtins.attrValues {
      inherit
        (pkgs.mpvScripts)
        sponsorblock
        ;
    };
  };

  xdg = {
    desktopEntries = {
      mpv = {
        name = "mpv";
        genericName = "Video Player";
        comment = "A free, open-source, cross-platform video player";
        exec = "mpv %U";
        icon = "mpv";
        type = "Application";
        categories = ["Player" "Video"];
        mimeType = ["video/*"];
      };
    };
    mimeApps.defaultApplications = {
      "video/*" = "mpv.desktop";
    };
  };
}
