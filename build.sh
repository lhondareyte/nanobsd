#!/bin/sh
#
LOCK="/tmp/do_not_shutdown.lk"
PATH=$PATH:/usr/local/bin
LABEL=$1
TARGET=$2
CONFIG="${HOME}/.etc/build.conf"
WORKDIR=$(dirname $0)
SMTPCONFIG="$HOME/.etc/smtp.conf"
MAILSEND="/usr/local/bin/mailsend"

[ -z $LABEL  ] && exit 0 
[ -z $TARGET ] && TARGET="all"

Mail () {
	if [ $MAIL = "no" ] ; then
		return
	fi
	if [ ! -f $SMTPCONFIG ] ; then
		return
	fi
	if [ ! -x $MAILSEND ] ; then
		return
	fi
	MSG=$1 
	. $SMTPCONFIG
	printf "${MSG}\nKisses." | $MAILSEND \
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
	echo "$CONFIG: no such file."
	exit 0
fi

TODAY="$(date +%d)"

if [ "${TODAY}" != "${DAY}" ] ; then
	Error 0 "Today is the day that I chuck."
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
[ -z $NANO_ARCH2 ] && NANO_ARCH2=$NANO_ARCH
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
		;;
	'install')
		dd if=nanobsd.img of=$NANO_DRIVE bs=64k > /dev/null 2>&1
		;;
	*)	
		echo "$(basename $0) <label> [all|world|kernel|diskimage|install]"
		exit 1
		;;
esac
touch $LOCK

cd $WORKDIR
${SUDO} cp ${KERNEL} /usr/src/sys/${NANO_ARCH2}/conf/${NANO_KERNEL}
if [ -f ${WORKDIR}/${LABEL}/.embedded ] ; then
	DISKIMAGE="/usr/embedded/images/_.disk.image.${NANO_NAME}"
	${SUDO} cp ${WORKDIR}/${LABEL}/nanobsd.conf ${NANODIR}/embedded/${LABEL}.cfg
	cd ${NANODIR}/embedded
	${SUDO} /bin/sh ${NANOSCRIPT} ${NANOPT} -c ${LABEL}.cfg
	rc=$?
else
	${SUDO} /bin/sh ${NANOSCRIPT} ${NANOPT} -c ${NANOCFG}
	rc=$?
fi

if [ $rc -eq 0 ] ; then
	Mail "${LABEL} build completed."
else
	Mail "${LABEL} build failed!"
fi

rm -f $LOCK
exit $rc
