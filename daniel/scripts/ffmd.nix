{ pkgs, ... }:
let
  ffgetmd = pkgs.writeShellApplication {
    name = "ffgetmd";
    runtimeInputs = with pkgs; [ ffmpeg ];
    text = ''
      ffmpeg -y -i "$1" -f ffmetadata /tmp/ffmetadata
      $EDITOR /tmp/ffmetadata
    '';
  };
  ffsetmd = pkgs.writeShellApplication {
    name = "ffsetmd";
    runtimeInputs = with pkgs; [ ffmpeg ];
    text = ''
      ffmpeg -i "$1" -i /tmp/ffmetadata -map_metadata 1 -movflags use_metadata_tags -codec copy "$2"
    '';
  };
in
{
  home.packages = [
    ffgetmd
    ffsetmd
  ];
}
