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
SUDO="/usr/local/bin/sudo"

NANODIR="/usr/src/tools/tools/nanobsd"
NANOSCRIPT="${NANODIR}/nanobsd.sh"
KERNEL="${WORKDIR}/${LABEL}/kernel.conf"
NANOCFG="${WORKDIR}/${LABEL}/nanobsd.conf"

Usage () {
	echo "Usage : $(basename $0) <label> [all|world|kernel|diskimage|burn]"
	exit 1
}

Mail () {
	MSG=$1 
	echo ${MSG}
	[ ${MAIL} = "no"     ] && return
	[ ! -f ${SMTPCONFIG} ] && return
	[ ! -x ${MAILSEND}   ] && return

	. ${SMTPCONFIG}
	printf "${MSG}\nKisses.\n\n- Send from $(hostname) -" | ${MAILSEND} \
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
[ ! -x ${NANOSCRIPT} ] && Error 1 "NanoBSD is not installed on this system."

case ${LABEL} in
	'etc'|'install'|'embedded')
		Usage
		;;
esac

if [ ! -e $SUDO ] ; then
	if [ $(id -u) -ne 0 ] ; then
		Error 1 "Please install 'sudo' or run this script as root"
	else
		unset SUDO
	fi
fi

if [ -f ${CONFIG} ] ; then
	. ${CONFIG}
	TODAY="$(date +%d)"
	if [ "${TODAY}" != "${DAY}" ] ; then
		Error 1 "Today is not the day that I chuck."
	fi
fi

if [ ! -d ${WORKDIR}/${LABEL} ] ; then
	Error 1 "${LABEL} : no such configuration."
fi

if ([ -f ${WORKDIR}/embedded/common ] && [ ${WORKDIR}/${LABEL}/.embedded ]) ; then
	${SUDO} cp ${WORKDIR}/embedded/common ${NANODIR}/embedded/
fi

. ${NANOCFG} 2>/dev/null

[ ! -f ${KERNEL}  ] && KERNEL="${WORKDIR}/generic/kernel.conf"
[ -z ${NANO_ARCH} ] && NANO_ARCH="amd64"
[ -z ${NANO_MACH} ] && NANO_MACH=${NANO_ARCH}

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
	'burn'|'install')
		${SUDO} dd if=${DISKIMAGE} of=${NANO_DRIVE} \
			bs=64k > /dev/null 2>&1
		;;
	*)	
		Usage
		;;
esac
touch ${LOCK}

cd ${WORKDIR}
${SUDO} cp ${KERNEL} /usr/src/sys/${NANO_MACH}/conf/${NANO_KERNEL}
if [ -f ${WORKDIR}/${LABEL}/.embedded ] ; then
	DISKIMAGE="/usr/embedded/images/_.disk.image.${NANO_NAME}"
	${SUDO} cp ${WORKDIR}/${LABEL}/nanobsd.conf \
		${NANODIR}/embedded/${LABEL}.cfg
	cd ${NANODIR}/embedded
	${SUDO} /bin/sh ${NANOSCRIPT} ${NANOPT} -c ${LABEL}.cfg
	rc=$?
else
	echo normal
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
