{config, ...}: let
  mod = "SUPER";
in ''
  # Input configuration
  numlockon=1
  xkb_rules_layout=us,gb
  xkb_rules_variant=dvorak,
  xkb_rules_options=caps:swapescape,grp:ctrls_toggle

  # Keybinds
  binds=${mod},x,spawn,${config.XF86.explorer}
  binds=${mod},Q,killclient
  binds=${mod},W,spawn,$BROWSER

  bind=${mod},Return,spawn,${config.programs.terminal}
''
