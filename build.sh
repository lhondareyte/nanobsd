#!/bin/sh
#
LOCK="/tmp/do_not_shutdown.lk"
PATH=$PATH:/usr/local/bin
LABEL=$1
TARGET=$2
CONFIG="${HOME}/.etc/build.conf"
MAIL="no"
WORKDIR=$(dirname $0)

[ -z $LABEL  ] && exit 0
[ -z $TARGET ] && TARGET="all"

Mail () {
	if [ $MAIL = "no" ] ; then
		return
	fi
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
		-sub "${LABEL} build" \
		-name "$FULLNAME"
}

Error() {
	local rc=$1 ; shift
	local msg=$*
	Mail "$msg"
	echo $msg
	rm -f $LOCK
	exit $rc

}

if [ -f $CONFIG ] ; then
	. $CONFIG
else
	exit 0
fi

TODAY="$(date +%d)"

if [ "${TODAY}" != "${DAY}" ] ; then
	Error 0 "Today is not the day."
fi

NANODIR="/usr/src/tools/tools/nanobsd"
NANOSCRIPT="${NANODIR}/nanobsd.sh"
KERNEL="${WORKDIR}/${LABEL}/kernel.conf"
NANOCFG="${WORKDIR}/${LABEL}/nanobsd.conf"

if [ ! -d ${WORKDIR}/${LABEL} ] ; then
	Error 1 "${LABEL} : no such configuration."
else
	. $NANOCFG 2>/dev/null
fi

[ $(id -u) -ne 0 ] && SUDO="sudo"
[ ! -f ${KERNEL} ] && KERNEL="${WORKDIR}/generic/kernel.conf"
[ -z $NANO_ARCH  ] && NANO_ARCH="amd64"
[ -z $NANO_ARCH2 ] && NANO_ARCH2=NANO_ARCH
DISKIMAGE="/usr/obj/nanobsd.${NANO_NAME}/_.disk.full"

case $TARGET in
	'all')
		NANOPT=""
		;;
	'world')
		NANOPT="-k -i"
		;;
	'kernel')
		NANOPT="-w -i"
		;;
	'diskimage')
		NANOPT="-k -w -b"
		mv $DISKIMAGE $WORKDIR
		;;
	'install')
		dd if=nanobsd.img of=$NANO_DRIVE bs=64k > /dev/null 2>&1
		;;
	*)	
		echo "$(basename $0) [all|world|kernel|diskimage|install]"
		exit 1
		;;
esac
touch $LOCK


${SUDO} cp ${KERNEL} /usr/src/sys/${NANO_ARCH2}/conf/${NANO_KERNEL}
/bin/sh ${NANOSCRIPT} ${NANOPT} -c ${NANOCFG}

if [ $rc -eq 0 ] ; then
	Mail "${LABEL} build completed."
else
	Mail "${LABEL} build failed!"
fi

rm -f $LOCK
exit $rc
