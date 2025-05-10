#!/bin/sh
#
LOCK="/tmp/do_not_shutdown.lk"
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
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

Exit() {
	local rc=$1 ; shift
	local msg=$*
	Mail "${msg}"
	rm -f ${LOCK}
	exit ${rc}
}

[ -z ${LABEL}  ] && Usage
[ -z ${TARGET} ] && TARGET="all"
[ -f ${LOCK}   ] && Exit 1 "There is already a build in progress."
[ ! -x ${NANOSCRIPT} ] && Exit 1 "NanoBSD is not installed on this system."

case ${LABEL} in
	'etc'|'install'|'embedded')
		Usage
		;;
esac

if [ ! -e $SUDO ] ; then
	if [ $(id -u) -ne 0 ] ; then
		Exit 1 "Please install 'sudo' or run this script as root"
	else
		unset SUDO
	fi
fi

if [ -f ${CONFIG} ] ; then
	. ${CONFIG}
	TODAY="$(/bin/date +%d)"
	if [ "${TODAY}" != "${DAY}" ] ; then
		Exit 1 "Today is not the day that I chuck ($TODAY vs $DAY)."
	fi
fi

if [ ! -d ${WORKDIR}/${LABEL} ] ; then
	Exit 1 "${LABEL} : no such configuration."
fi

if ([ -f ${WORKDIR}/embedded/common ] && [ ${WORKDIR}/${LABEL}/.embedded ]) ; then
	${SUDO} cp ${WORKDIR}/embedded/common ${NANODIR}/embedded/
fi

. ${NANOCFG} 2>/dev/null

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
if [ -f ${KERNEL} ] ; then
	${SUDO} cp ${KERNEL} /usr/src/sys/${NANO_MACH}/conf/${NANO_KERNEL}
else
	${SUDO} cp ${NANO_MACH}/kernel.conf /usr/src/sys/${NANO_MACH}/conf/${NANO_KERNEL}
fi

if [ -f ${WORKDIR}/${LABEL}/.embedded ] ; then
	DISKIMAGE="/usr/embedded/images/_.disk.image.${NANO_NAME}"
	${SUDO} cp ${WORKDIR}/${LABEL}/nanobsd.conf \
		${NANODIR}/embedded/${LABEL}.cfg
	cd ${NANODIR}/embedded
	${SUDO} /bin/sh ${NANOSCRIPT} ${NANOPT} -c ${LABEL}.cfg
	rc=$?
else
	${SUDO} /bin/sh ${NANOSCRIPT} ${NANOPT} -c ${NANOCFG}
	rc=$?
fi

MSG="build completed."
if [ $rc -ne 0 ] ; then
	MSG="build failed."
fi
Exit $rc  "${LABEL} ${MSG}"
