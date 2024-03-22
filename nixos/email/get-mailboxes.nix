{pkgs}:
pkgs.writeShellScriptBin "get-mailboxes" ''
  while getopts ":a:i:I:" o; do case "''${o}" in
      a) address="$OPTARG" ;;
      i) imap="$OPTARG" ;;
      I) iport="$OPTARG" ;;
      *) echo "Options:
      -a your@email.com   Your email address
      -i                  IMAP server address
      -I                  IMAP server port"; exit 1 ;;
  esac done

  ${pkgs.curl}/bin/curl --location-trusted -s --user "$address:$(${pkgs.pass}/bin/pass "$address")" --url "imaps://$imap:''${iport:-993}" | sed "s/\"//g;s/.*\/ /\"=/;s/$/\"\ /" | tr -d "\r" | tr -d "\n"
''
