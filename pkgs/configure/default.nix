{
  alejandra,
  bat,
  git,
  libnotify,
  nh,
  ripgrep,
  writeShellApplication,
  ...
}:
writeShellApplication
{
  name = "configure";
  runtimeInputs = [git bat ripgrep libnotify nh alejandra];
  text = builtins.readFile ./configure.sh;
}
