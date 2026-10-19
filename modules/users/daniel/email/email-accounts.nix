{config, ...}: {
  users.daniel.emailAccounts = {
    imports = with config.users.daniel; [pass];

    home-manager.users.daniel = {
      config,
      lib,
      pkgs,
      ...
    }: let
      maildirBasePath = "${config.xdg.dataHome}/email";
      mkEmailAccount = address: overrides:
        lib.nameValuePair address (lib.recursiveUpdate {
            inherit address;
            userName = address;
            realName = "Daniel Laing";
            passwordCommand = "${lib.getExe pkgs.pass} show email/${address}";

            imap = {
              port = 993;
            };

            smtp = {
              port = 465;
            };

            folders = {
              drafts = "Drafts";
              inbox = "INBOX";
              sent = "Sent";
              trash = "Trash";
            };

            mbsync = {
              enable = true;
              create = "maildir";
              # remove = "maildir";
            };

            msmtp.enable = true;
            neomutt.enable = true;
            notmuch.enable = true;
            # thunderbird.enable = true;
          }
          overrides);
    in {
      # Create directories we will need
      home.activation.prepareMailDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${lib.getExe' pkgs.coreutils "mkdir"} -p -m 0700 -- ${lib.escapeShellArg maildirBasePath}
      '';

      accounts.email = {
        inherit maildirBasePath;
        accounts = lib.listToAttrs [
          (mkEmailAccount "daniel@daniellaing.com" {
            primary = true;

            imap.host = "mail.daniellaing.com";
            smtp = {
              host = "mail.daniellaing.com";
              port = 587;
              tls.useStartTls = true;
            };
            folders.trash = "Bin";

            gpg = {
              key = "daniel@daniellaing.com";
              signByDefault = true;
            };
          })

          (mkEmailAccount "bodleum.phone@gmail.com" {
            imap.host = "imap.gmail.com";
            smtp.host = "smtp.gmail.com";
            flavor = "gmail.com";
          })

          (mkEmailAccount "daniellaing@talktalk.net" {
            imap.host = "mail.talktalk.net";
            smtp = {
              host = "smtp.talktalk.net";
              port = 587;
              tls.useStartTls = true;
            };
          })
        ];
      };
    };
  };
}
