STEPS=		base boot cdrom chroot clean core distfiles \
		kernel nano plugins ports prefetch print rebase \
		release serial sign skim test vga vm xtools
.PHONY:		${STEPS}

PAGER?=		less

all:
	@cat ${.CURDIR}/README.md | ${PAGER}

lint:
. for STEP in ${STEPS}
	@sh -n ${.CURDIR}/build/${STEP}.sh
. endfor

# Load the custom options from a file:

.if defined(CONFIG)
.include "${CONFIG}"
.endif

# Bootstrap the build options if not set:

NAME?=		OPNsense
TYPE?=		${NAME:tl}
SUFFIX?=	#-devel
FLAVOUR?=	OpenSSL
SETTINGS?=	16.7
_ARCH!=		uname -p
ARCH?=		${_ARCH}
DEVICE?=	a10
SPEED?=		115200
UEFI?=		yes
MIRRORS?=	https://opnsense.c0urier.net \
		http://mirrors.nycbug.org/pub/opnsense \
		http://mirror.wdc1.us.leaseweb.net/opnsense \
		http://mirror.sfo12.us.leaseweb.net/opnsense \
		http://mirror.fra10.de.leaseweb.net/opnsense \
		http://mirror.ams1.nl.leaseweb.net/opnsense
_VERSION!=	date '+%Y%m%d%H%M'
VERSION?=	${_VERSION}
STAGEDIRPREFIX?=/usr/obj
PORTSREFDIR?=	/usr/freebsd-ports
PLUGINSDIR?=	/usr/plugins
TOOLSDIR?=	/usr/tools
PORTSDIR?=	/usr/ports
COREDIR?=	/usr/core
SRCDIR?=	/usr/src

# A couple of meta-targets for easy use and ordering:

ports distfiles: base
plugins: ports
core: plugins
packages: core
cdrom vm serial vga nano: packages kernel
sets: distfiles packages kernel
images: cdrom nano serial vga vm
release: cdrom nano serial vga

# Expand target arguments for the script append:

.for TARGET in ${.TARGETS}
_TARGET=	${TARGET:C/\-.*//}
.if ${_TARGET} != ${TARGET}
${_TARGET}_ARGS+=	${TARGET:C/^[^\-]*(\-|\$)//:S/,/ /g}
${TARGET}: ${_TARGET}
.endif
.endfor

.if "${VERBOSE}" != ""
VERBOSE_FLAGS=	-x
.else
VERBOSE_HIDDEN=	@
.endif

# Expand build steps to launch into the selected
# script with the proper build options set:

.for STEP in ${STEPS}
${STEP}: lint
	${VERBOSE_HIDDEN} cd ${.CURDIR}/build && \
	    sh ${VERBOSE_FLAGS} ./${.TARGET}.sh -a ${ARCH} \
	    -f ${FLAVOUR} -n ${NAME} -v ${VERSION} -s ${SETTINGS} \
	    -S ${SRCDIR} -P ${PORTSDIR} -p ${PLUGINSDIR} -T ${TOOLSDIR} \
	    -C ${COREDIR} -R ${PORTSREFDIR} -t ${TYPE} -k "${PRIVKEY}" \
	    -K "${PUBKEY}" -l "${SIGNCHK}" -L "${SIGNCMD}" -d ${DEVICE} \
	    -m ${MIRRORS:Ox:[1]} -o "${STAGEDIRPREFIX}" -c ${SPEED} \
	    -u "${UEFI:tl}" -U "${SUFFIX}" ${${STEP}_ARGS}
.endfor
