{ config, pkgs, ... }:

let
  realName = "Daniel Laing";
  gpg = {
    key = "daniel@daniellaing.com";
    signByDefault = true;
  };
in
{
  accounts.email.maildirBasePath = "${config.xdg.dataHome}/email";
  accounts.email.accounts = {

    # ---   daniel@daniellaing.com   ---
    Daniel = {
      thunderbird.enable = true;

      address = "daniel@daniellaing.com";
      userName = "daniel@daniellaing.com";
      primary = true;
      imap = {
        host = "mail.daniellaing.com";
        port = 993;
      };
      smtp = {
        host = "mail.daniellaing.com";
        port = 587;
        tls = {
          enable = true;
          useStartTls = true;
        };
      };
      folders = {
        inbox = "INBOX";
        drafts = "Drafts";
        trash = "Bin";
        sent = "Sent";
      };
      mbsync = {
        enable = true;
        create = "both";
        expunge = "both";
        remove = "both";
        subFolders = "Verbatim";
      };
      msmtp.enable = true;
      passwordCommand = "pass daniel@daniellaing.com";
      notmuch.enable = true;

      realName = realName;
      maildir.path = "daniel@daniellaing.com";
      gpg = gpg;
    };


    # ---   bodleum.phone@gmail.com   ---
    GMail = {
      thunderbird.enable = true;

      address = "bodleum.phone@gmail.com";
      flavor = "gmail.com";
      imap = {
        host = "imap.gmail.com";
        port = 993;
      };
      smtp = {
        host = "smtp.gmail.com";
        port = 587;
        tls = {
          enable = true;
          useStartTls = true;
        };
      };
      folders = {
        inbox = "INBOX";
        drafts = "Drafts";
        trash = "Trash";
        sent = "Sent";
      };
      mbsync = {
        enable = true;
        create = "both";
        expunge = "both";
        remove = "both";
        subFolders = "Verbatim";
      };
      msmtp.enable = true;
      passwordCommand = "pass bodleum.phone@gmail.com";
      notmuch.enable = true;

      realName = realName;
      maildir.path = "bodleum.phone@gmail.com";
      gpg = gpg;
    };


    # ---   daniellaing@talktalk.net   ---
    TalkTalk = {
      thunderbird.enable = true;

      address = "daniellaing@talktalk.net";
      userName = "daniellaing@talktalk.net";
      imap = {
        host = "mail.talktalk.net";
        port = 993;
      };
      smtp = {
        host = "smtp.talktalk.net";
        port = 587;
        tls = {
          enable = true;
          useStartTls = true;
        };
      };
      folders = {
        inbox = "INBOX";
        drafts = "Drafts";
        trash = "Trash";
        sent = "Sent";
      };
      mbsync = {
        enable = true;
        create = "both";
        expunge = "both";
        remove = "both";
        subFolders = "Verbatim";
      };
      msmtp.enable = true;
      passwordCommand = "pass daniellaing@talktalk.net";
      notmuch.enable = true;

      realName = realName;
      maildir.path = "daniellaing@talktalk.net";
      gpg = gpg;
    };
  };

}
