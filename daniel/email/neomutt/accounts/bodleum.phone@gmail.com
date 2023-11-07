# Neomuttrc for bodleum.phone@gmail.com

set realname                = "Daniel Laing"
set hostname                = "gmail.com"
set from                    = "bodleum.phone@gmail.com"
set sendmail                = "msmtp -a GMail"
set folder                  = "~/.local/share/email/bodleum.phone@gmail.com"
set header_cache            = "~/.cache/email/bodleum.phone@gmail.com/headers"
set message_cachedir        = "~/.cache/email/bodleum.phone@gmail.com/bodies"
set mbox_type               = Maildir
#set pgp_default_key         = "bodleum.phone@gmail.com"          # Default key for PGP

my_hdr Cc: bodleum.phone@gmail.com
set spoolfile               = +INBOX
set postponed               = +Drafts
set trash                   = +Trash
set record                  = +Sent

mailboxes `get-mailboxes -a bodleum.phone@gmail.com -i imap.gmail.com -I 993 | sed "s/\"=\[Gmail\]\"\ //;s/\"=\[Gmail\]\/All\ Mail\"\ //"`

macro index         o       "<shell-escape>sync-email bodleum.phone@gmail.com<Enter>"      "Sync bodleum.phone@gmail.com"

alias me Daniel Laing <bodleum.phone@gmail.com>
