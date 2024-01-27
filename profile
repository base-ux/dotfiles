#
# ~/.profile
#

# Determine shell
if   test -n "${BASH_VERSION}" ; then
    _sh=bash
elif test -n "${KSH_VERSION}" ; then
    _sh=ksh
elif test -n "${FCEDIT}" ; then
    _sh=ksh
else
    _sh=sh
fi

# Set terminal type
TERM=${TERM:-xterm}
export TERM

# Add some directories to PATH if they exist
for _p in \
	/usr/bin /bin /usr/local/bin \
	/usr/sbin /sbin /usr/local/sbin \
	/usr/es/sbin/cluster/utilities \
	/opt/freeware/bin \
	${HOME}/bin
do
    if test -d ${_p}; then
	case ":${PATH}:" in
	    *:"${_p}":*) ;;
	    *) PATH=${PATH}:${_p}
	esac
    fi
done
unset _p
export PATH

# Set manpages path
if test -x /usr/bin/manpath ; then
    # For Linux (which has manpath binary)
    test -n "${MANPATH}" && unset MANPATH
else
    MANPATH=/usr/share/man
    # Add some directories to MANPATH if they exist
    for _p in /usr/local/man \
	      /usr/local/share/man \
	      /opt/freeware/man \
	      /usr/opt/rpm/man
    do
	test -d ${_p} && MANPATH=${MANPATH}:${_p}
    done
    unset _p
    export MANPATH
fi

# Set some variables if not set
test -n "${UID}"      || UID=`id -ur 2>/dev/null`
test -n "${EUID}"     || EUID=`id -u 2>/dev/null`
test -n "${USER}"     || USER=`id -un 2>/dev/null`
test -n "${LOGNAME}"  || LOGNAME=${USER}
test -n "${HOSTNAME}" || HOSTNAME=`hostname`
test -n "${HOST}"     || HOST=${HOSTNAME}
test -n "${MAIL}"     || MAIL=/var/spool/mail/${USER}
test -n "${MAILMSG}"  || MAILMSG="[YOU HAVE NEW MAIL]"
# Do NOT export UID, EUID, USER, and LOGNAME
export HOST HOSTNAME MAIL MAILMSG

# Set locale to POSIX for root
if test ${EUID} -eq 0 ; then
    LC_ALL=C
    if test -x /usr/bin/locale ; then
	# Little Linux hack
	/usr/bin/locale -a 2>/dev/null | grep -q '^C\.utf8$' 2>/dev/null
	test $? -eq 0 && LC_ALL=C.UTF-8
    fi
    export LC_ALL
fi

# Set other variables
TZ=Europe/Moscow
EDITOR=vi
export TZ EDITOR

# Set 'less' as PAGER if exist
if test -x /usr/bin/less -o -x /opt/freeware/bin/less ; then
    PAGER=less
    LESS=-FMR
    export PAGER LESS
else
    PAGER=more
    export PAGER
fi

# Source user environment file if exist
test -f ${HOME}/.env && . ${HOME}/.env || true

# Source appropriate .*shrc
if test "${_sh}" = "bash" ; then
    test -f ${HOME}/.bashrc && . ${HOME}/.bashrc || true
elif test "${_sh}" = "ksh" ; then
    test -f ${HOME}/.kshrc && . ${HOME}/.kshrc || true
fi
unset _sh

# Check mail at startup
test -s ${MAIL} && echo "${MAILMSG}"
