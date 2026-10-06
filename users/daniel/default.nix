{
  inputs,
  pkgs,
  ...
}: {
  # home-manager.users.daniel = {
  home = {
    packages = builtins.attrValues {
      inherit
        (pkgs)
        ffmpeg-full
        steam
        ;
    };
  };
  # };
}
