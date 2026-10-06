{
  users.daniel.ffmpeg = {
    home-manager.users.daniel = {
      nixpkgs.overlays = [
        # Override ffmpeg to allow for unfree codecs and so on
        (final: prev: {
          ffmpeg-full =
            (prev.ffmpeg-full.override {
              withUnfree = true;
            }).overrideAttrs (_: {
              doCheck = false;
            });
        })
      ];
    };
  };
}
