#!/usr/bin/sh
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

# Print error message
err()
{
    echo "${PROG}: error: $@"
}

# Copy single source file to destination file
copy_file()
{
    $local _src="$1"
    $local _dst="$2"

    # Check source file
    if ! test -f "${_src}" ; then
	err "file '${_src}' not found"
	return
    fi
    # Check destination file
    if test -f "${_dst}" ; then
	# If destination file in place check for differences
	diff "${_src}" "${_dst}" >/dev/null 2>/dev/null
	test $? -eq 0 && return		# No differences
	# Check for write permissions
	if ! test -w "${_dst}" ; then
	    err "file '${_dst}' not writable"
	    # Try to remove before copying
	    rm -f "${_dst}" 2>/dev/null
	    if test $? -ne 0 ; then
		err "can't delete file '${_dst}'"
		return
	    fi
	fi
    fi
    # Try to copy file
    cp "${_src}" "${_dst}" 2>/dev/null
    test $? -eq 0 || err "can't copy file '${_src}' to file '${_dst}'"
}

PROG="$(basename $0)"

SRCDIR="$(dirname $0)"
DSTDIR="${HOME}"

PROFILEFILES="
bashrc
exrc
inputrc
kshrc
profile
vimrc
"

for _f in ${PROFILEFILES} ; do
    copy_file "${SRCDIR}/${_f}" "${DSTDIR}/.${_f}"
done
