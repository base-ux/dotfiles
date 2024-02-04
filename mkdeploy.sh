#!/bin/sh

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

: ${SRCDIR:="$(pwd)"}
: ${OUTDIR:="$(pwd)"}
: ${OUTFILE:="deploy.sh"}
: ${FILELIST:=""}
: ${INITFILE:=""}
: ${PRODUCT:=""}
: ${VERSION:=""}

: ${WORKDIR:=/tmp/${PROG}.$$}

MD5SUM=""

encode_cmd=""
pack_cmd=""
chksum_cmd=""

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

# Print first found command in the list
find_command ()
{
    local _cmd=""

    for _cmd in "$@" ; do
	command -v "${_cmd}" >/dev/null 2>&1 && { echo "${_cmd}" ; return ; } || continue
    done
    echo ""
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

# Checksum methods

chksum_md5sum ()
{
    cmd md5sum "${W_ARCH}"
}

chksum_openssl ()
{
    cmd openssl md5 -r "${W_ARCH}"
}

# Encode methods

encode_uuencode ()
{
    cmd uuencode -m /dev/stdout | cmd sed -e '1d;$d' > "${W_BLOB}"
}

encode_base64 ()
{
    cmd base64 > "${W_BLOB}"
}

encode_openssl ()
{
    cmd openssl enc -a -out "${W_BLOB}"
}

# Pack methods

pack_pax ()
{
    (
	cd "${SRCDIR}"
	cmd pax -w -x ustar -f "${W_ARCH}" ${FILELIST} ${INITFILE}
    )
}

pack_tar ()
{
    cmd tar -c -f "${W_ARCH}" -C "${SRCDIR}" ${FILELIST} ${INITFILE}
}

###

# Initialization subroutine
startup ()
{
    local _f=""

    # Check binaries
    # Encode
    encode_cmd="$(find_command uuencode base64 openssl)"
    if test -z "${encode_cmd}" ; then
	err "can't find encode binary"
	return 1
    fi
    # Pack
    pack_cmd="$(find_command pax tar)"
    if test -z "${pack_cmd}" ; then
	err "can't find pack binary"
	return 1
    fi
    # MD5 (if there is no MD5 binary then do not check MD5 sum)
    chksum_cmd="$(find_command md5sum openssl)"

    # Check variables
    {
	check_var FILELIST &&
	check_var INITFILE
    } || return 1

    # Normalize output file path
    case "${OUTFILE}" in
	( /* ) OUTDIR="$(dirname -- "${OUTFILE}")" ;;
	(  * ) OUTFILE="${OUTDIR}/${OUTFILE}" ;;
    esac

    # Check directories
    if ! test -d "${SRCDIR}" ; then
	err "directory '${SRCDIR}' doesn't exist"
	return 1
    fi
    if ! test -d "${OUTDIR}" ; then
	err "directory '${OUTDIR}' doesn't exist"
	return 1
    fi

    # Check files
    for _f in ${FILELIST} ${INITFILE} ; do
	test -r "${SRCDIR}/${_f}" && continue
	err "file '${_f}' not found in directory '${SRCDIR}'"
	return 1
    done

    # Check working directory
    check_dir "${WORKDIR}" || return 1

    # Set working filenames
    W_ARCH="${WORKDIR}/archive.pax"
    W_BLOB="${WORKDIR}/blob"
    W_OUT="${WORKDIR}/out.sh"
}

# Create archive
mkpack ()
{
    if ! pack_${pack_cmd} ; then
	err "can't pack file '${W_ARCH}'"
	return 1
    fi
    if test -n "${chksum_cmd}" ; then
	MD5SUM="$(chksum_${chksum_cmd})"
	MD5SUM="${MD5SUM%%[[:space:]]*}"
    fi
}

# Create blob
mkblob ()
{
    if ! cat "${W_ARCH}" | encode_${encode_cmd} ; then
	err "can't encode file '${W_ARCH}'"
	return 1
    fi
}

# Generate deploy script
mkdeploy ()
{
    embed > "${W_OUT}"
}

# Copy generated deploy script
cpdeploy ()
{
    cmd cp "${W_OUT}" "${OUTFILE}"
    if test $? -ne 0 ; then
	err "can't copy file '${W_OUT}' to file '${OUTFILE}'"
	return 1
    fi
}

# Clean working directory
cleanup ()
{
    if test -n "${WORKDIR}" ; then
	cmd rm -f "${W_ARCH}"
	cmd rm -f "${W_BLOB}"
	cmd rm -f "${W_OUT}"
	cmd rmdir "${WORKDIR}"
    fi
}

# Exit with error code
fail ()
{
    exit 1
}

# Clean up the staff and exit with error
clean_fail ()
{
    cleanup
    fail
}

###

usage ()
{
    cat << EOF
Usage: ${PROG} [-d destdir] [-f file]... [-i initfile] [-o outfile] [-s srcdir]
	[-w workdir] [-P product] [-V version]
EOF
}

usage_help ()
{
    usage
    cat << EOF

    -d destdir	where to write output file (default: current directory)
    -f file	file to add to archive (path relative to srcdir)
    -i initfile	init-file to execute by deploy after unpacking
    -o outfile	output file name (either absolute name or relative to destdir)
    -s srcdir	where to look source files (default: current directory)
    -w workdir	where to place temporary working files (default: /tmp)
    -P product	product name to write to deploy file
    -V version	version of product to write to deploy file
EOF
    exit 0
}

get_options ()
{
    local _opt=""

    case "$1" in ( '-?' | '-help' | '--help' ) usage_help ;; esac
    while getopts ":d:f:i:o:s:w:P:V:" _opt ; do
	case "${_opt}" in
	    ( 'd' ) OUTDIR="${OPTARG}"   ;;
	    ( 'i' ) INITFILE="${OPTARG}" ;;
	    ( 'o' ) OUTFILE="${OPTARG}"  ;;
	    ( 's' ) SRCDIR="${OPTARG}"   ;;
	    ( 'w' ) WORKDIR="${OPTARG}"  ;;
	    ( 'P' ) PRODUCT="${OPTARG}"  ;;
	    ( 'V' ) VERSION="${OPTARG}"  ;;
	    ( 'f' ) FILELIST="${FILELIST:+"${FILELIST} "}${OPTARG}" ;;
	    ( ':' )
		err "missing argument for option -- '${OPTARG}'"
		usage
		return 1
		;;
	    ( '?' )
		err "unknown option -- '${OPTARG}'"
		usage
		return 1
		;;
	    (  *  )
		err "no handler for option '${_opt}'"
		return 1
		;;
	esac
    done
    shift $((${OPTIND} - 1))
    if test $# -gt 0 ; then
	err "too many arguments"
	usage
	return 1
    fi
}

###

# Main subroutine
main ()
{
    trap 'cleanup; exit 130' HUP INT TERM
    get_options "$@" && startup || fail
    {
	mkpack   &&
	mkblob   &&
	mkdeploy &&
	cpdeploy
    } || clean_fail
    cleanup
}

###
### Embedded deploy.sh script ###
###

embed ()
{
    cat << 'BEGIN' ; cat << PARAMS ; cat << 'MAIN' ; cat << BLOB ; cat << 'END'
#!/bin/sh

BEGIN
### Deploy parameters

PRODUCT="${PRODUCT}"
VERSION="${VERSION}"

INITFILE="${INITFILE}"
MD5SUM="${MD5SUM}"

PARAMS
###

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

: ${XDG_CACHE_HOME:="${HOME}/.cache"}

BASEDIR="${XDG_CACHE_HOME}/spxshell/deploy"
DEPLOYDIR="${BASEDIR}/${MD5SUM:-none}"
LOCKFILE="${DEPLOYDIR}/deploy.lock"

EDIR="${DEPLOYDIR}/e"
XDIR="${DEPLOYDIR}/x"

ARCHFILE="${EDIR}/archive.pax"
INITFILE="${XDIR}/${INITFILE}"

decode_cmd=""
unpack_cmd=""
chksum_cmd=""

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

# Print first found command in the list
find_command ()
{
    local _cmd=""

    for _cmd in "$@" ; do
	command -v "${_cmd}" >/dev/null 2>&1 && { echo "${_cmd}" ; return ; } || continue
    done
    echo ""
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

# Check for lock file existance or create it
check_lock ()
{
    local _lock="$1"

    test -n "${_lock}" || return 1
    if test -f "${_lock}" ; then
	err "lock file '${_lock}' found. Another process running?"
	return 1
    else
	# Try to create lock file
	cmd touch "${_lock}"
	if test $? -ne 0 ; then
	    err "can't create lock file '${_lock}'"
	    return 1
	fi
    fi
}

###

# Checksum methods

chksum_md5sum ()
{
    cmd md5sum "${ARCHFILE}"
}

chksum_openssl ()
{
    cmd openssl md5 -r "${ARCHFILE}"
}

# Decode methods

decode_uudecode ()
{
    {
	echo "begin-base64 644 /dev/stdout"
	cat
	echo "===="
    } | cmd uudecode -o "${ARCHFILE}"
}

decode_base64 ()
{
    cmd base64 -d > "${ARCHFILE}"
}

decode_openssl ()
{
    cmd openssl enc -d -a -out "${ARCHFILE}"
}

# Unpack methods

unpack_pax ()
{
    cmd pax -r -f "${ARCHFILE}" -s ",^,${XDIR}/,"
}

unpack_tar ()
{
    cmd tar -x -f "${ARCHFILE}" -C "${XDIR}"
}

###

# Initialization subroutine
startup ()
{
    local _umask=""

    # Check binaries
    # Extract
    decode_cmd="$(find_command uudecode base64 openssl)"
    if test -z "${decode_cmd}" ; then
	err "can't find extract binary"
	return 1
    fi
    # Unpack
    unpack_cmd="$(find_command pax tar)"
    if test -z "${unpack_cmd}" ; then
	err "can't find unpack binary"
	return 1
    fi
    # MD5 (if there is no MD5 binary then do not check MD5 sum)
    test -n "${MD5SUM}" && chksum_cmd="$(find_command md5sum openssl)"

    # Check directories
    {
	_umask="$(umask)"	# Save umask value
	umask 0077		# Create only user accessible directories
	check_dir "${DEPLOYDIR}" &&
	check_dir "${EDIR}"      &&
	check_dir "${XDIR}"      &&
	umask "${_umask}"	# Restore umask
    } || return 1

    # Check lock file
    check_lock "${LOCKFILE}"  || return 1
}

# Extract archive from embedded blob
extract ()
{
    local _md5=""

    if ! blob | decode_${decode_cmd} ; then
	err "can't extract file '${ARCHFILE}'"
	return 1
    fi
    if test -n "${chksum_cmd}" ; then
	_md5="$(chksum_${chksum_cmd})"
	_md5="${_md5%%[[:space:]]*}"
	if test "${MD5SUM}" != "${_md5}" ; then
	    err "incorrect checksum for file '${ARCHFILE}'"
	    return 1
	fi
    fi
}

# Unpack archive
unpack ()
{
    if ! unpack_${unpack_cmd} ; then
	err "can't unpack file '${ARCHFILE}'"
	return 1
    fi
}

# Execute defined init file
execinit ()
{
    if ! test -f "${INITFILE}" ; then
	err "execution program '${INITFILE}' is not found"
	return 1
    elif test -x "${INITFILE}" ; then
	"${INITFILE}"
    else
	command -p sh "${INITFILE}"
    fi
}

# Save version information
bumpver ()
{
    if test -n "${PRODUCT}" -a -n "${VERSION}" ; then
	cmd echo "${VERSION}" > "${BASEDIR}/${PRODUCT}"
    fi
}

# Clean deployment directory
cleanup ()
{
    if test -n "${DEPLOYDIR}" ; then
	test -n "$trapped" && trap - HUP INT TERM
	cmd find "${DEPLOYDIR}" -depth ! -type d -exec rm -f {} \+
	cmd find "${DEPLOYDIR}" -depth -type d -exec rmdir {} \+
    fi
}

# Exit with error code
fail ()
{
    exit 1
}

# Clean up the staff and exit with error
clean_fail ()
{
    cleanup
    fail
}

# Main subroutine
main ()
{
    trap 'trapped=true cleanup; exit 130' HUP INT TERM
    startup || fail
    {
	extract  &&
	unpack   &&
	execinit &&
	bumpver
    } || clean_fail
    cleanup
}

## Embedded blob ##

blob ()
{
    cat << EOF
MAIN
$(cat "${W_BLOB}")
BLOB
EOF
}

## End of embedded blob ##

# Call main subroutine
main "$@"
END
}

###
### End of embedded script ###
###

# Call main subroutine
main "$@"
