{pkgs}:
pkgs.writeShellScriptBin "sync-email" ''
  # Script to sync emails

  # Run only if user is logged in
  pgrep -u "''${USER:=LOGNAME}" > /dev/null || { echo "$USER not logged in; sync will not run."; exit ; }

  # Run only if not already running
  pgrep mbsync > /dev/null && { echo "mbsync is already running."; exit ; }

  # First, we have to get the right variables for the mbsync file, the pass
  # archive, notmuch and the GPG home.
  eval "$(grep -h -- \
           "^\s*\(export \)\?\(MBSYNCRC\|PASSWORD_STORE_DIR\|NOTMUCH_CONFIG\|GNUPGHOME\)=" \
           "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.zprofile"  "$HOME/.config/zsh/.zprofile" "$HOME/.zshenv" \
           "$HOME/.config/zsh/.zshenv" "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.config/zsh/.zshrc" \
           "$HOME/.pam_environment" 2>/dev/null)"

   export GPG_TTY="$(tty)"


   [ -n "$MBSYNCRC" ] && alias mbsync="${pkgs.isync}/bin/mbsync -c $MBSYNCRC" || MBSYNCRC="$HOME/.mbsyncrc"

  # Settings are different for MacOS (Darwin) systems.
   case "$(readlink -f /sbin/init)" in
       *systemd*|*openrc*) export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus ;;
   esac
  # remember if a display server is running since `ps` doesn't always contain a display
   pgrepoutput="$(pgrep -a X\(org\|wayland\))"
   displays="$(echo "$pgrepoutput" | grep -wo "[0-9]*:[0-9]\+" | sort -u)"
   notify() { [ -n "$pgrepoutput" ] && for x in ''${displays:-0:}; do
       export DISPLAY=$x ${pkgs.libnotify}/bin/notify-send --app-name="Neomutt" "New email!" "📬 $2 new email(s) in \`$1\` account."
   done ;}

  # Check account for new email. Notify if there is new content.
   syncandnotify() {
       acc="$(echo "$account" | sed "s/.*\///")"
       if [ -z "$opts" ]; then ${pkgs.isync}/bin/mbsync -c $MBSYNCRC "$acc"; else ${pkgs.isync}/bin/mbsync -c $MBSYNCRC "$opts" "$acc"; fi
       new=$(find\
               "$HOME/.local/share/email/$acc/INBOX/new/"\
               "$HOME/.local/share/email/$acc/Inbox/new/"\
               "$HOME/.local/share/email/$acc/inbox/new/"\
               "$HOME/.local/share/email/$acc/INBOX/cur/"\
               "$HOME/.local/share/email/$acc/Inbox/cur/"\
               "$HOME/.local/share/email/$acc/inbox/cur/"\
               -type f -newer "''${XDG_CONFIG_HOME:-\$HOME/.config}/neomutt/.emailsynclastrun" 2> /dev/null)
       newcount=$(echo "$new" | sed '/^\s*$/d' | wc -l)
       case 1 in
           $((newcount > 0)) ) notify "$acc" "$newcount" ;;
       esac
   }

  # Sync accounts passed as argument or all.
  if [ "$#" -eq "0" ]; then
      accounts="$(awk '/^Channel/ {print $2}' "$MBSYNCRC")"
  else
      for arg in "$@"; do
          [ "''${arg%''${arg#?}}" = '-' ] && opts="''${opts:+''${opts} }''${arg}" && shift 1
      done
      accounts=$*
  fi

  # Parallelize multiple accounts
  for account in $accounts; do
      syncandnotify &
  done

  wait

  ${pkgs.notmuch}/bin/notmuch new 2>/dev/null

  #Create a touch file that indicates the time of the last run of emailsync
  touch "''${XDG_CONFIG_HOME:-$HOME/.config}/neomutt/.emailsynclastrun"
''
