#
# ~/.kshrc
#

# Use this file only if stdin is terminal
[[ -t 0 ]] || return

# Set some shell variables and options
[[ -n "${UID}"  ]] || UID=$(id -u)
[[ -n "${USER}" ]] || USER=$(id -un)
[[ -n "${HOST}" ]] || HOST=$(hostname)
HISTSIZE=1000

# Set shell options
set -o vi
set -o viraw
[[ -n "${KSH_VERSION}" ]] && set -o multiline	# ksh93

# Set timeout for root
if [[ "${UID}" -eq 0 ]]; then
    TMOUT=120
fi

# Set prompt
PS1='${USER}@${HOST}:${PWD}> '
[[ -n "${KSH_VERSION}" ]] && PS1='($(date +%H:%M)) '${PS1}	# ksh93
# Colorize prompt
if [[ -n "${TERM}" && -t 0 ]]; then
    _off="$(tput sgr0 2>/dev/null)"	# Turn off
    _bold="$(tput bold 2>/dev/null)"	# Bold
    _colg="$(tput setaf 2 2>/dev/null)"	# Green
    _colr="$(tput setaf 1 2>/dev/null)"	# Red
    if [[ -z "${_colg}" || -z "${_colr}" ]]; then
	# setaf capability is not set, try setf instead
	_colg="$(tput setf 2 2>/dev/null)"	# Green
	_colr="$(tput setf 4 2>/dev/null)"	# Red
    fi
    if [[ "${UID}" -eq 0 ]]; then
	# For root user
	_on="${_bold}${_colr}"
    else
	# For ordinary user
	case "$(uname -s)" in
	AIX*)   _on="${_bold}" ;;	# Only bold for AIX
	Linux*) _on="${_bold}${_colg}" ;;
	esac
    fi
    if [[ -n "${_on}" && -n "${_off}" ]]; then
	PS1="${_on}${PS1% }${_off} "
    fi
    unset _bold _colg _colr _on _off
fi

# Source aliases and functions if they exist
for _f in ${HOME}/.aliases ${HOME}/.functions
do
    [[ -f ${_f} ]] && . ${_f}
done
unset _f
