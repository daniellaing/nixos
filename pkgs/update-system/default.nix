{
  git,
  libnotify,
  nh,
  writeShellApplication,
  ...
}: (writeShellApplication {
  name = "update-system";
  runtimeInputs = [git libnotify nh];
  text = builtins.readFile ./update-system.sh;
})
