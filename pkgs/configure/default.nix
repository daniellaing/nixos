{
  alejandra,
  git,
  libnotify,
  nh,
  writeShellApplication,
  ...
}:
writeShellApplication
{
  name = "configure";
  runtimeInputs = [alejandra git libnotify nh];
  text = builtins.readFile ./configure.sh;
}
