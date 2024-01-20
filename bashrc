#
# ~/.bashrc
#

# Use this file only for interactive shell
case "$-" in ( *i* ) ;; ( * ) return ;; esac

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

# Get operating system name
_os="$(uname -s)"

# Set some shell variables if not set
test -n "${UID}"  || UID=$(id -ur)
test -n "${EUID}" || EUID=$(id -u)
test -n "${USER}" || USER=$(id -un)
test -n "${HOST}" || HOST=$(hostname)

# Set shell options
case "${_sh}" in
    ksh* )
	set -o vi
	set -o viraw
	case "$(set -o)" in ( *multiline* ) set -o multiline ;; esac
	;;
esac

# History options
HISTSIZE=1000
case "$(set -o)" in ( *histexpand* ) set -o histexpand ;; esac
case "${_sh}" in
    bash* )
	shopt -s histappend
	HISTCONTROL=ignoreboth
	HISTTIMEFORMAT="%F %T %Z  "
	;;
esac

# Set timeout for root
if test ${EUID} -eq 0 ; then
    TMOUT=120
fi

# Set prompt
case "${_sh}" in
    bash* )
	PS1='[\A] \u@\h:\w\$ ' ;;
    ksh* )
	PS1='${USER}@${HOST}:${PWD}> '
	test "${_sh}" = "ksh93" && PS1="(\$(date +%H:%M)) ${PS1}"
	;;
esac

# Colorize prompt
if test -n "${TERM}" -a -t 0 ; then
    _off="$(tput sgr0 2>/dev/null)"		# Turn off
    _bold="$(tput bold 2>/dev/null)"		# Bold
    _colu="$(tput setaf 4 2>/dev/null)"		# Blue
    _colr="$(tput setaf 1 2>/dev/null)"		# Red
    if test -z "${_colu}" ; then
	# setaf capability is not set, try setf instead
	_colu="$(tput setf 1 2>/dev/null)"	# Blue
	_colr="$(tput setf 4 2>/dev/null)"	# Red
    fi
    if test ${EUID} -eq 0 ; then
	# For root user
	_on="${_bold}${_colr}"
    else
	# For ordinary user
	case "${_os}" in
	    AIX* )   _on="${_bold}" ;;		# Only bold for AIX
	    Linux* ) _on="${_bold}${_colu}" ;;
	esac
    fi
    if test -n "${_on}" -a -n "${_off}" ; then
	case "${_sh}" in
	    bash* ) PS1="\[${_on}\]${PS1% }\[${_off}\] " ;;
	    ksh*  ) PS1="${_on}${PS1% }${_off} " ;;
	esac
    fi
    unset _bold _colu _colr _on _off
fi

# Source aliases and functions if they exist
for _f in ${HOME}/.alias ${HOME}/.aliases ${HOME}/.functions ; do
    test -f "${_f}" && . "${_f}" || true
done
unset _f
unset _sh _os
