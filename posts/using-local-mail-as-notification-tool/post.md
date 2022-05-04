# Using local mail as notification tool

Post created at 2022-05-04 14:25

I used to run commands and develop into linux terminal, and have some scheduled tasks running in the background.

I need to be notified on terminal about some finished processes in a generic form, without depending GUI notifications.

By default, every cron job thats writes to console is sent to user local email. So, local email will be my notification messages repository.

## Setup

I used this setup in Ubuntu, but it must works in any distro.

1. Adding current user to __mail__ group

```bash
$ sudo adduser $USER mail
Adding user 'guionardo' to group 'mail' ...
Adding user guionardo to group mail
Done.
```

2. Install mailtools, postfix, and mutt

```bash
$ sudo apt install mailtools postfix mutt
```

3. Send test mail

```bash
$ echo "This is a test" | mail "--subject=Test email" $USER@localhost
```

4. Test new mail

```bash
$ mail
"/var/mail/guionardo": 1 message 1 new
>N   1 Guionardo Furlan   qua mai  4 17:41  14/464   Test email
? q
Held 1 message in /var/mail/guionardo
```

Ok, we have an e-mail into our inbox. Lets read with better tool.

```bash
$ mutt
```

```bash
q:Quit  d:Del  u:Undel  s:Save  m:Mail  r:Reply  g:Group  ?:Help
   1 O F mai 04 To guionardo@lo (   2) Test email



---Mutt: /var/mail/guionardo [Msgs:1 Old:1 0,6K]---(threads/date)----(all)---
```

```bash
i:Exit  -:PrevPg  <Space>:NextPg v:View Attachm.  d:Del  r:Reply  j:Next ?:He
Date: Wed,  4 May 2022 17:41:20 +0000 (UTC)
From: Guionardo Furlan <guionardo@furlan-server>
To: guionardo@localhost
Subject: Test email
X-Mailer: mail (GNU Mailutils 3.7)

This is a test


-O F- 1/1: Guionardo Furlan       Test email                         -- (all)
```

5. Setup for notifications

Add this content to your ~/.profile or equivalent file (.bashrc, .zshrc, etc):

```bash
MAIL_CHECK_TIME=0
mail_prompt() {
    local pwd='~'
    local MAIL_SECONDS_DIFF=$MAILCHECK

    local MAIL_ELAPSED_SECONDS=$((SECONDS - MAIL_CHECK_TIME))

    [ "$PWD" != "$HOME" ] && pwd=${PWD/#$HOME\//\~\/}

    printf "\033]0;%s@%s:%s\033\\%s" "${USER}" "${HOSTNAME%%.*}" "${pwd}"

    if [[ "$MAIL_CHECK_TIME" -eq "0" || "$MAIL_ELAPSED_SECONDS" -gt "$MAIL_SECONDS_DIFF" ]]; then
        local MAILX="$(mailx 2>/dev/null &)"
        UNREADEN_REGEX="\s([0-9]{1,4})\sn"
        [[ $MAILX =~ $UNREADEN_REGEX ]] && UNREADEN=$(echo "${BASH_REMATCH[1]}") || UNREADEN=0
        local COUNT=$((UNREADEN))
        local MESSAGE_TEXT="message"
        if [ "$COUNT" -gt "0" ]; then
            if [ "$COUNT" -gt "1" ]; then
                MESSAGE_TEXT="messages"
            fi
            echo "$COUNT unreaden $MESSAGE_TEXT. Run mutt"
        fi
        MAIL_CHECK_TIME=$SECONDS
    fi

}

if [[ $(which mailx) ]]; then
    PROMPT_COMMAND="mail_prompt"
fi
```

6. Close and reopen your terminal to load this configuration
7. Now, when you access the terminal, messages not readden will show a prompt:

```bash
1 unreaden message. Run mutt
```

In your custom scripts, you can send email to your local user and get notified.
