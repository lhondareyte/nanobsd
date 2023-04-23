#!/bin/sh
#
LOCK="/tmp/do_not_shutdown.lk"
PATH=${PATH}:/usr/local/bin
LABEL=$1
TARGET=$2
WORKDIR=$(dirname $0)
CONFIG="${HOME}/.etc/build.conf"
SMTPCONFIG="${HOME}/.etc/smtp.conf"
MAILSEND="/usr/local/bin/mailsend"

NANODIR="/usr/src/tools/tools/nanobsd"
NANOSCRIPT="${NANODIR}/nanobsd.sh"
KERNEL="${WORKDIR}/${LABEL}/kernel.conf"
NANOCFG="${WORKDIR}/${LABEL}/nanobsd.conf"

Usage () {
	echo "Usage : $(basename $0) <label> [all|world|kernel|diskimage|install]"
	exit 1
}

Mail () {
	MSG=$1 
	echo ${MSG}

	[ ${MAIL} = "no"     ] && return
	[ ! -f ${SMTPCONFIG} ] && return
	[ ! -x ${MAILSEND}   ] && return

	. ${SMTPCONFIG}
	printf "${MSG}\nKisses." | ${MAILSEND} \
		-starttls -auth-login \
		-smtp ${SERVER} \
		-port ${PORT} \
		-t "${DEST}" \
		-f "${USER}" \
		-pass ${PASSWD} \
		-user ${USER} \
		-sub "${LABEL} build" \
		-name "${FULLNAME}" -q

}

Error() {
	local rc=$1 ; shift
	local msg=$*
	Mail "${msg}"
	rm -f ${LOCK}
	exit ${rc}
}

[ -z ${LABEL}  ] && Usage
[ -z ${TARGET} ] && TARGET="all"

if [ -f ${CONFIG} ] ; then
	. ${CONFIG}
	TODAY="$(date +%d)"
	if [ "${TODAY}" != "${DAY}" ] ; then
		Error 1 "Today is not the day that I chuck."
	fi
fi
if [ ! -d ${WORKDIR}/${LABEL} ] ; then
	Error 1 "${LABEL} : no such configuration."
else
	. ${NANOCFG} 2>/dev/null
fi

[ $(id -u) -ne 0   ] && SUDO="sudo"
[ ! -f ${KERNEL}   ] && KERNEL="${WORKDIR}/generic/kernel.conf"
[ -z ${NANO_ARCH}  ] && NANO_ARCH="amd64"
[ -z ${NANO_ARCH2} ] && NANO_ARCH2=${NANO_ARCH}

DISKIMAGE="/usr/obj/nanobsd.${NANO_NAME}/_.disk.full"

case ${TARGET} in
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
		dd if=nanobsd.img of=${NANO_DRIVE} bs=64k > /dev/null 2>&1
		;;
	*)	
		Usage
		;;
esac
touch ${LOCK}

cd ${WORKDIR}
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

rm -f ${LOCK}
exit $rc
