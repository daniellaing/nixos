# Neomuttrc for daniel@daniellaing.com

set realname                = "Daniel Laing"
set hostname                = "daniellaing.com"
set from                    = "daniel@daniellaing.com"
set sendmail                = "msmtp -a Daniel"
set folder                  = "~/.local/share/email/daniel@daniellaing.com"
set header_cache            = "~/.cache/email/daniel@daniellaing.com/headers"
set message_cachedir        = "~/.cache/email/daniel@daniellaing.com/bodies"
set mbox_type               = Maildir
set crypt_autosign          = yes                               # Automatically sign outgoing messages
set pgp_default_key         = "daniel@daniellaing.com"          # Default key for PGP

my_hdr Cc: daniel@daniellaing.com
set spoolfile               = =INBOX
set postponed               = =Drafts
set trash                   = =Bin
set record                  = =Sent

mailboxes `get-mailboxes -a daniel@daniellaing.com -i mail.daniellaing.com -I 993`

macro index         o       "<shell-escape>sync-email daniel@daniellaing.com<Enter>"      "Sync daniel@daniellaing.com"

alias me Daniel Laing <daniel@daniellaing.com>
