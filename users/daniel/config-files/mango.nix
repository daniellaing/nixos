{config, ...}: let
  mod = "SUPER";
in ''
  exec=pkill waybar; waybar

  animations=0
  cursor_hide_timeout=3
  cursor_hide_on_keypress=1

  # Input configuration
  numlockon=1
  xkb_rules_layout=us,gb
  xkb_rules_variant=dvorak,
  xkb_rules_options=caps:swapescape,grp:ctrls_toggle

  # Keybinds
  # binds=${mod},a,
  # binds=${mod},b,
  # binds=${mod},c,
  # binds=${mod},d,
  # binds=${mod},e,
  binds=${mod},f,togglefullscreen
  binds=${mod},g,togglegaps
  # binds=${mod},h,
  # binds=${mod},i,
  binds=${mod},j,focusstack,next
  binds=${mod},k,focusstack,prev
  # binds=${mod},l,
  binds=${mod},m,spawn,${config.XF86.music}
  # binds=${mod},n,
  # binds=${mod},o,
  binds=${mod},p,spawn,${config.XF86.audioPlay}
  binds=${mod},q,killclient
  # binds=${mod},r,
  # binds=${mod},s,
  # binds=${mod},t,
  # binds=${mod},u,
  # binds=${mod},v,
  binds=${mod},w,spawn,$BROWSER
  binds=${mod},x,spawn,${config.XF86.explorer}
  # binds=${mod},y,
  # binds=${mod},z,

  binds=${mod},comma,spawn,${config.XF86.audioPrev}
  binds=${mod},period,spawn,${config.XF86.audioNext}
  bind=${mod},Return,spawn,${config.programs.terminal}
  bind=ALT,Space,spawn_shell,wofi -S drun -I

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
