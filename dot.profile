#
# ~/.profile
#

# Determine shell
if   test -n "${BASH_VERSION}" ; then
    _sh=bash
elif test -n "${KSH_VERSION}" ; then
    _sh=ksh93
elif test -n "${FCEDIT}" ; then
    _sh=ksh
else
    _sh=sh
fi

_is_cmd ()
{
    command -v "$1" >/dev/null 2>&1
}

# Set PATH
if _is_cmd getconf ; then
    _path="`getconf PATH`"
fi
# Add some directories to PATH if they exist
_path="${_path:+${_path}:}/bin:/usr/bin:/usr/local/bin"
_path="${_path}:/sbin:/usr/sbin:/usr/local/sbin"
_path="${_path}:/opt/freeware/bin"		# for AIX
_path="${_path}:/usr/es/sbin/cluster/utilities"	# for PowerHA
_path="${_path}:${HOME}/bin:${HOME}/.local/bin"
_path="${_path}:${PATH}"
# Check and remove duplicates
_ifs="${IFS}"
IFS=":"
for _p in ${_path} ; do
    case ":${_npath}:" in
	*":${_p}:"* ) ;;
	* ) test -d "${_p}" && _npath="${_npath:+${_npath}:}${_p}" ;;
    esac
done
IFS="${_ifs}"
PATH="${_npath}"
unset _path _npath _ifs _p
export PATH

# Set manpages path
if _is_cmd manpath ; then
    # For Linux (which has manpath binary)
    unset MANPATH
    unset MANPATHISSET
else
    MANPATH=/usr/share/man
    # Add some directories to MANPATH if they exist
    _manpath="/usr/local/man /usr/local/share/man"
    _manpath="${_manpath} /opt/freeware/man /usr/opt/rpm/man"	# for AIX
    for _p in ${_manpath} ; do
	test -d "${_p}" && MANPATH="${MANPATH}:${_p}"
    done
    unset _manpath _p
    export MANPATH
fi

# Set terminal type
TERM="${TERM:-xterm}"
export TERM

# Set some variables if not set
if _is_cmd id ; then
    test -n "${UID}"      || UID="`id -ur 2>/dev/null`"
    test -n "${EUID}"     || EUID="`id -u 2>/dev/null`"
    test -n "${USER}"     || USER="`id -un 2>/dev/null`"
    test -n "${LOGNAME}"  || LOGNAME="${USER}"
    test -n "${MAIL}"     || MAIL="/var/spool/mail/${USER}"
    test -n "${MAILMSG}"  || MAILMSG="[YOU HAVE NEW MAIL]"
    # Do NOT export UID, EUID, USER, and LOGNAME
    export MAIL MAILMSG
fi
if _is_cmd hostname ; then
    test -n "${HOSTNAME}" || HOSTNAME="`hostname`"
    test -n "${HOST}"     || HOST="${HOSTNAME}"
    export HOST HOSTNAME
fi

# Set locale to POSIX for root
if test -n "${EUID}" && test "${EUID}" -eq 0 ; then
    LC_ALL="C"
    if _is_cmd locale ; then
	# Little Linux hack
	case " `locale -a` " in
	    *[[:space:]]"C.utf8"[[:space:]]* ) LC_ALL="C.UTF-8" ;;
	esac
    fi
    export LC_ALL
fi

# Set XDG Base Directory variables
: ${XDG_CACHE_HOME:="${HOME}/.cache"}
: ${XDG_CONFIG_HOME:="${HOME}/.config"}
: ${XDG_DATA_HOME:="${HOME}/.local/share"}
: ${XDG_STATE_HOME:="${HOME}/.local/state"}
export XDG_CACHE_HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME

# Set other variables
TZ="Europe/Moscow"
EDITOR="vi"
export TZ EDITOR

# Set 'less' as PAGER if exist
if _is_cmd less ; then
    PAGER="less"
    LESS="-FMR"
    export LESS
else
    PAGER="more"
fi
export PAGER

# Source user environment file if exist
test -f "${HOME}/.env" && . "${HOME}/.env" || true

# Source appropriate .*shrc
if test "${_sh}" = "bash" ; then
    _rc="${HOME}/.bashrc"
elif test "${_sh}" = "ksh" ; then
    # ksh93 sets ENV variable and will source .kshrc after .profile
    _rc="${HOME}/.kshrc"
else
    _rc=""
fi
_inprofile="true"	# Check this variable in rc
test -n "${_rc}" && test -f "${_rc}" && . "${_rc}" || true
unset _rc _inprofile

# Check mail at startup
test -n "${MAIL}" && test -s "${MAIL}" && echo "${MAILMSG}"

# Unset used local variables and functions
unset _sh
unset -f _is_cmd
