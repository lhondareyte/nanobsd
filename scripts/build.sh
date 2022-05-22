#!/bin/sh
#
LOCK="/tmp/do_not_shutdown.lk"
PATH=$PATH:$HOME/bin
label=$1
confile="${HOME}/.etc/build.conf"

if [ -z $label ] ; then
   exit 0
fi

Mail () {
   MSG=$1 
   . $HOME/.etc/smtp.conf
   printf "${MSG}\nKisses." | mailsend \
            -smtp $SERVER \
            -port $PORT \
            -starttls \
            -auth-login \
            -t "$DEST" \
            -f "$USER" \
            -pass $PASSWD \
            -user $USER \
            -sub "${label} build" \
            -name "$FULLNAME"
}

if [ -f $confile ] ; then
   . $confile
else
   exit 0
fi

TODAY="$(date +%d)"

if [ "${TODAY}" != "${DAY}" ] ; then
   Mail "Today is not the day."
   exit 0
fi

touch $LOCK
cd $NANO_DIR && make $label && sudo make diskimage

if [ $? -eq 0 ] ; then
   Mail "${label} build completed."
else
   Mail "${label} build failed!"
fi
rm -f $LOCK
