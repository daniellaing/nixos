{
  ffmpeg,
  mktemp,
  writeShellApplication,
  ...
}:
writeShellApplication
{
  name = "ffmd";
  runtimeInputs = [ffmpeg mktemp];
  text = builtins.readFile ./ffmd.sh;
}
