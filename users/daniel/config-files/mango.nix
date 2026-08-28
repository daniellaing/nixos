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

  bind=${mod},1,view,1
  bind=${mod},2,view,2
  bind=${mod},3,view,3
  bind=${mod},4,view,4
  bind=${mod},5,view,5
  bind=${mod},6,view,6
  bind=${mod},7,view,7
  bind=${mod},8,view,8
  bind=${mod},9,view,9

  bind=${mod}+SHIFT,1,tag,1
  bind=${mod}+SHIFT,2,tag,2
  bind=${mod}+SHIFT,3,tag,3
  bind=${mod}+SHIFT,4,tag,4
  bind=${mod}+SHIFT,5,tag,5
  bind=${mod}+SHIFT,6,tag,6
  bind=${mod}+SHIFT,7,tag,7
  bind=${mod}+SHIFT,8,tag,8
  bind=${mod}+SHIFT,9,tag,9
''
