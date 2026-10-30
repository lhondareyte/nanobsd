#!/bin/sh
#
# Copyright (c)2022-2026  Luc Hondareyte
# All rights reserved.
#
# SPDX-License-Identifier: BSD-2-Clause
#

PRG="$(basename "${0}")"
LOCK="/tmp/do_not_shutdown.lk"
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
LABEL="${1}"
TARGET="${2}"
CONFIG="${HOME}/.etc/build.conf"
SMTPCONFIG="${HOME}/.etc/smtp.conf"
MAILSEND="/usr/local/bin/mailsend"
SUDO="/usr/local/bin/sudo"

SOURCES="/usr/src"

WORKDIR="$(dirname "${0}")"
EMBEDDED="${WORKDIR}/embedded"
NANODIR="${SOURCES}/tools/tools/nanobsd"
NANOSCRIPT="${NANODIR}/nanobsd.sh"
KERNEL="${WORKDIR}/${LABEL}/kernel.conf"
NANOCFG="${WORKDIR}/${LABEL}/nanobsd.conf"
MAIL="no"
LOCKED="no"

Usage () {
	Exit --no-mail 1 "Usage : ${PRG} <label> [all|world|kernel|diskimage]"
}

Mail () {
	MSG=$1 
	echo "${MSG}"
	[ "${MAIL}" = "no"     ] && return
	[ ! -f "${SMTPCONFIG}" ] && return
	[ ! -x "${MAILSEND}"   ] && return

	. "${SMTPCONFIG}"
	printf '%s\nKisses.\n\n- Send from %s -' "${MSG}" "$(hostname)" | ${MAILSEND} \
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
	rc=$1
	if [ "${rc}" = "--no-mail" ] ; then
		MAIL="no"
		shift
		rc=$1
	fi
	shift
	msg=$*
	if [ "${LOCKED}" = "yes" ] ; then
		mnt=$(mount | awk '/nanobsd/ {print $3}')
		if ! ([ ! -z "${mnt}" ] && ${SUDO} umount "${mnt}" || : ) ; then
			echo "Failed to umount ${mnt}"
		fi
		mnt=$(mount | awk '/embedded/ {print $3}')
		if ! ([ ! -z "${mnt}" ] && ${SUDO} umount "${mnt}" || : ) ; then
			echo "Failed to umount ${mnt}"
		fi
		rmdir "${LOCK}"
	fi
	Mail "${msg}"
	exit ${rc}
}

trap 'Exit 1 "Something went wrong"' 1 2 5 6

[ -z "${LABEL}"  ] && Usage
[ -z "${TARGET}" ] && TARGET="all"
[ ! -x "${NANOSCRIPT}" ] && Exit 1 "NanoBSD is not installed on this system."

case "${LABEL}" in
	'etc'|'install'|'embedded')
		Usage
		;;
esac

if [ ! -d "${WORKDIR}/${LABEL}" ] ; then
	Exit --no-mail 1 "${LABEL} : no such configuration."
fi

if [ ! -e "$SUDO" ] ; then
	if [ $(id -u) -ne 0 ] ; then
		Exit 1 "Please install 'sudo' or run this script as root"
	else
		unset SUDO
	fi
fi

if [ -f "${CONFIG}" ] ; then
	. "${CONFIG}"
	TODAY="$(/bin/date +%d)"
	if [ "${TODAY}" != "${DAY}" ] ; then
		Exit 1 "Today is the day that I chuck."
	fi
fi

if  ! mkdir "${LOCK}" ; then 
	Exit 1 "There is already a build in progress."
fi
LOCKED="yes"

if ([ -f "${EMBEDDED}/common" ] && [ -f "${WORKDIR}/${LABEL}/.embedded" ]) ; then
	${SUDO} cp "${EMBEDDED}/common" "${NANODIR}/embedded/common.local"
fi

. ${NANOCFG} 2>/dev/null

if ([ ! -z "${NANO_LOCAL_PACKAGES}" ] && [ ! -f /usr/ports/Mk/bsd.port.mk ]) ; then
	Exit 1 "Ports are not installed"
fi

NANO_ARCH="${NANO_ARCH:-amd64}"
NANO_MACH="${NANO_MACH:-$NANO_ARCH}"

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
		if ${SUDO} dd if="${DISKIMAGE}" of="${NANO_DRIVE}" bs=64k ; then
    			Exit 0 "${LABEL} : disk image written."
		else
    			Exit 1 "${LABEL} : disk image write failed."
		fi
		;;
	*)	
		Usage
		;;
esac

cd "${WORKDIR}"

if [ -f "${KERNEL}" ] ; then
	if ! ( ${SUDO} cp "${KERNEL}" \ 
	                  "${SOURCES}/sys/${NANO_MACH}/conf/${NANO_KERNEL}" ) ; then
		Exit 1 "Failed to copy kernel configuration file"
	fi
else
	if ! (${SUDO} cp "${WORKDIR}/${NANO_MACH}/kernel.conf" \
	           "${SOURCES}/sys/${NANO_MACH}/conf/${NANO_KERNEL}") ; then
		Exit 1 "Failed to copy kernel configuration file"
	fi
fi

if [ -f "${WORKDIR}/${LABEL}/.embedded" ] ; then
	DISKIMAGE="/usr/embedded/images/_.disk.image.${NANO_NAME}"
	if ! (${SUDO} cp "${WORKDIR}/${LABEL}/nanobsd.conf" \
	           "${NANODIR}/embedded/${LABEL}.cfg") ; then
		Exit 1 "Failed to copy nanobsd configuration file"
	fi

	cd ${NANODIR}/embedded && \
	${SUDO} /bin/sh "${NANOSCRIPT}" "${NANOPT}" -c "${LABEL}.cfg"
	rc=$?
else
	${SUDO} /bin/sh "${NANOSCRIPT}" "${NANOPT}" -c "${NANOCFG}"
	rc=$?
fi

MSG="build completed."
if [ $rc -ne 0 ] ; then
	MSG="build failed."
fi
Exit $rc "${LABEL} ${MSG}"
