{pkgs}:
pkgs.writeShellScriptBin "neomutt-account-switcher" ''
  /usr/bin/env ls -1 ''${XDG_CONFIG_HOME:-$HOME/.config}/neomutt/accounts | ${pkgs.rofi}/bin/rofi -dmenu -p "Which account?"
''
