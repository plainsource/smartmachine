#!/bin/sh
PERCENT=$1
USER=$2
cat << EOF | /usr/lib/dovecot/dovecot-lda -d $USER -o "plugin/quota=maildir:User quota:noenforcing"
From: Email Postmaster <postmaster@%<mailname>s>
Subject: Your mailbox is $PERCENT% full.

Hello there,

Your mailbox can store a limited amount of emails. Currently it is $PERCENT% full. New emails will not be stored if you reach 100%.

To get more space in your mailbox you can:
1. Contact your email provider and upgrade your plan.
2. Delete emails from your mailbox.

If using option 2, please ensure you have emptied your Trash folder to free up the space.

Thanks for reading. Hope this was helpful.

Regards,
Your Email Postmaster
EOF
