#!/bin/sh
#
# Installation script
#

# Unset all aliases
'unalias' -a

# Ensure 'command' is not a user function
unset -f command

# Use shell dependent 'local' definition
local="$(command -v local)"
test -z "${local}" && local="$(command -v typeset)"
alias local="${local}"

###

# Set variables
PROG="$(basename -- "$0")"

SRCDIR="$(cd -- "$(dirname -- "$0")" ; pwd)"
DSTDIR="${HOME}"

: ${XDG_DATA_HOME:="${HOME}/.local/share"}

BCKDIR="${XDG_DATA_HOME}/spxshell/backup"
BACKUP="no"	# No backup by default

COPYFILES="
dot.bashrc
dot.exrc
dot.inputrc
dot.profile
dot.vimrc
"

LINKFILES="
dot.bashrc:dot.kshrc
"

REMOVEFILES="
dot.bash_profile
dot.bash_login
"

###

# Print error message
err ()
{
    echo "${PROG}: error: $@" >&2
}

# Execute command and discard stderr
cmd ()
{
    command ${1+"$@"} 2>/dev/null
}

# Check directory availability or create it
check_dir ()
{
    local _dir="$1"

    test -n "${_dir}" || return 1
    if test -e "${_dir}" ; then
	if ! test -d "${_dir}" ; then
	    err "'${_dir}' is not directory"
	    return 1
	elif ! test -w "${_dir}" ; then
	    err "directory '${_dir}' is not writable"
	    return 1
	fi
    else
	# Try to create directory
	cmd mkdir -p "${_dir}"
	if test $? -ne 0 ; then
	    err "can't create directory '${_dir}'"
	    return 1
	fi
    fi
}

# Check for empty variable
check_var ()
{
    local _var="$1"

    test -n "${_var}" || return 1
    eval test -n \"\${${_var}}\"
    if test $? -ne 0 ; then
	err "'${_var}' is not set"
	return 1
    fi
}

###

# Copy single source file to destination file
copy_file ()
{
    local _src="$1"
    local _dst="$2"

    test -n "${_src}" -a -n "${_dst}" || return 1
    # Check source file
    if ! test -f "${_src}" ; then
	err "file '${_src}' not found"
	return 1
    fi
    # Check destination file
    if test -f "${_dst}" ; then
	# If destination file in place check for differences
	cmd diff "${_src}" "${_dst}" >/dev/null
	test $? -eq 0 && return 0	# No differences
	# Check for write permissions
	if ! test -w "${_dst}" ; then
	    err "file '${_dst}' not writable"
	    # Try to remove before copying
	    cmd rm -f "${_dst}"
	    if test $? -ne 0 ; then
		err "can't delete file '${_dst}'"
		return 1
	    fi
	fi
    fi
    # Try to copy file
    cmd cp "${_src}" "${_dst}"
    if test $? -ne 0 ; then
	err "can't copy file '${_src}' to file '${_dst}'"
	return 1
    fi
}

# Initialization subroutine
startup ()
{
    local _umask=""

    # Check variables
    {
	check_var SRCDIR &&
	check_var DSTDIR
    } || return 1

    # Check destination directory
    check_dir "${DSTDIR}" || return 1

    # Backup destination files only for the first time
    # and if the backup directory is successfully created
    if test -d "${BCKDIR}" ; then
	BACKUP="no"
    else
	# Try to create directory
	_umask="$(umask)"	# Save umask value
	umask 0077		# Create only user accessible directories
	cmd mkdir -p "${BCKDIR}"
	test $? -ne 0 && BACKUP="no" || BACKUP="yes"
	umask "${_umask}"	# Restore umask
    fi
}

# Copy files
copy_files ()
{
    local _f=""
    local _src=""
    local _dst=""

    for _f in ${COPYFILES} ; do
	_src="${SRCDIR}/${_f}"
	_dst="${DSTDIR}/${_f#dot}"
	# Try to backup destination file
	# Ignore unsuccessful copying
	test "${BACKUP}" = "yes" -a -f "${_dst}" && cmd cp "${_dst}" "${BCKDIR}"
	copy_file "${_src}" "${_dst}"
    done
}

# Link files
link_files ()
{
    local _f=""
    local _src=""
    local _dst=""

    for _f in ${LINKFILES} ; do
	_src="${_f%:*}"
	test -n "${_src}" -a "${_src}" != "${_f}" && _src="${_src#dot}" || continue
	_dst="${_f#*:}"
	test -n "${_dst}" -a "${_dst}" != "${_f}" && _dst="${DSTDIR}/${_dst#dot}" || continue
	# Skip if the link exists
	test -L "${_dst}" && continue
	# Try to backup file
	test "${BACKUP}" = "yes" -a -f "${_dst}" && cmd cp "${_dst}" "${BCKDIR}"
	cmd ln -sf "${_src}" "${_dst}"
	if test $? -ne 0 ; then
	    err "can't create symbolic link '${_src}' -> '${_dst}'"
	fi
    done
}

# Remove files
remove_files ()
{
    local _f=""
    local _dst=""

    for _f in ${REMOVEFILES} ; do
	_dst="${DSTDIR}/${_f#dot}"
	if test -f "${_dst}" ; then
	    # Try to backup file
	    test "${BACKUP}" = "yes" && cmd cp "${_dst}" "${BCKDIR}"
	    # Try to remove file
	    cmd rm -f "${_dst}"
	    if test $? -ne 0 ; then
		err "can't delete file '${_dst}'"
	    fi
	fi
    done
}

# Main subroutine
main ()
{
    startup || return 1
    copy_files
    link_files
    remove_files
}

# Call main subroutine
main "$@"
